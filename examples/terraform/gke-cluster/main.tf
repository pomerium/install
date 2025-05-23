terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.services_cidr
  }
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  
  name     = var.cluster_name
  location = var.zone != "" ? var.zone : var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }
  
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    network_policy_config {
      disabled = !var.enable_network_policy
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }
  
  network_policy {
    enabled = var.enable_network_policy
  }
  
  release_channel {
    channel = var.release_channel
  }
  
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
  
  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }
  
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  provider   = google-beta
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone != "" ? var.zone : var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    preemptible     = var.preemptible_nodes
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = "pd-standard"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    labels = var.node_labels
    
    tags = var.node_tags
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

resource "google_compute_firewall" "ssh_from_cluster" {
  count = var.enable_ssh_vm ? 1 : 0
  
  name    = "${var.cluster_name}-allow-ssh-from-cluster"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.pods_cidr]
  target_tags   = ["pomerium-ssh-target"]
}

resource "google_compute_address" "ssh_vm" {
  count = var.enable_ssh_vm ? 1 : 0
  
  name         = "${var.cluster_name}-ssh-vm-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_instance" "ssh_target" {
  count = var.enable_ssh_vm ? 1 : 0
  
  name         = "${var.cluster_name}-ssh-target"
  machine_type = "e2-micro"
  zone         = var.zone != "" ? var.zone : data.google_compute_zones.available[0].names[0]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }
  
  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    
    access_config {
      nat_ip = google_compute_address.ssh_vm[0].address
    }
  }
  
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y openssh-server
    
    # Create a demo user
    useradd -m -s /bin/bash pomerium-demo
    echo "pomerium-demo:demo-password" | chpasswd
    
    # Enable password authentication for demo purposes
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Install some demo applications
    apt-get install -y htop curl wget git vim
  EOT
  
  tags = ["pomerium-ssh-target"]
  
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  
  labels = {
    purpose = "pomerium-ssh-demo"
  }
}

data "google_compute_zones" "available" {
  count  = var.zone == "" ? 1 : 0
  region = var.region
}

data "google_client_config" "default" {}

output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE cluster name"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE cluster endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  description = "Cluster CA certificate"
  sensitive   = true
}

output "access_token" {
  value       = data.google_client_config.default.access_token
  description = "Access token for kubectl"
  sensitive   = true
}

output "kubectl_config_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project_id}"
  description = "Command to configure kubectl"
}

output "ssh_vm_external_ip" {
  value       = var.enable_ssh_vm ? google_compute_address.ssh_vm[0].address : null
  description = "External IP of the SSH target VM"
}

output "ssh_vm_internal_ip" {
  value       = var.enable_ssh_vm ? google_compute_instance.ssh_target[0].network_interface[0].network_ip : null
  description = "Internal IP of the SSH target VM"
}

output "vpc_network_name" {
  value       = google_compute_network.vpc.name
  description = "Name of the VPC network"
}