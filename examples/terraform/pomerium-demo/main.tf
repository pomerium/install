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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  project_id   = "pomerium-public-demo"
  domain       = "demo.pomerium.com"
  cluster_name = "pomerium-demo-cluster"
  region       = "us-central1"
  zone         = "us-central1-a"
}

provider "google" {
  project = local.project_id
  region  = local.region
}

provider "google-beta" {
  project = local.project_id
  region  = local.region
}

# Create dedicated VPC for demo
resource "google_compute_network" "demo_vpc" {
  name                    = "${local.cluster_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC for Pomerium public demo environment"
}

# Create subnet with secondary ranges for GKE
resource "google_compute_subnetwork" "demo_subnet" {
  name          = "${local.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = local.region
  network       = google_compute_network.demo_vpc.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Reserve static IPs for the demo
resource "google_compute_address" "pomerium_lb" {
  name         = "${local.cluster_name}-pomerium-lb"
  address_type = "EXTERNAL"
  description  = "Static IP for Pomerium LoadBalancer"
}

# GKE Cluster optimized for demo
resource "google_container_cluster" "demo" {
  provider = google-beta
  
  name     = local.cluster_name
  location = local.zone
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.demo_vpc.name
  subnetwork = google_compute_subnetwork.demo_subnet.name
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  
  # Public cluster for demo accessibility
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }
  
  workload_identity_config {
    workload_pool = "${local.project_id}.svc.id.goog"
  }
  
  addons_config {
    network_policy_config {
      disabled = false
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    
    dns_cache_config {
      enabled = true
    }
  }
  
  network_policy {
    enabled = true
  }
  
  release_channel {
    channel = "REGULAR"
  }
  
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
  
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    
    managed_prometheus {
      enabled = true
    }
  }
  
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
}

# Node pool for demo workloads
resource "google_container_node_pool" "demo_nodes" {
  provider   = google-beta
  name       = "${local.cluster_name}-nodes"
  location   = local.zone
  cluster    = google_container_cluster.demo.name
  
  initial_node_count = 3
  
  autoscaling {
    min_node_count = 2
    max_node_count = 6
  }

  node_config {
    preemptible     = false  # For demo stability
    machine_type    = "e2-standard-4"
    disk_size_gb    = 100
    disk_type       = "pd-standard"
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
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
    
    labels = {
      environment = "demo"
      purpose     = "pomerium-public-demo"
    }
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

# Configure Kubernetes provider
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.demo.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.demo.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.demo.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.demo.master_auth[0].cluster_ca_certificate)
  }
}

# Deploy Pomerium Enterprise
module "pomerium_enterprise" {
  source = "../../../../recipe/ingress-controller-enterprise-terraform-gke"
  
  depends_on = [google_container_node_pool.demo_nodes]
  
  gcp_project             = local.project_id
  gcp_region              = local.region
  domain                  = local.domain
  license_key             = var.pomerium_license_key
  image_registry_password = var.pomerium_registry_password
  administrators          = var.demo_administrators
  prefix                  = "demo"
  
  # Use smaller database for demo
  db_tier = "db-f1-micro"
  
  providers = {
    kubernetes = kubernetes
  }
}

# Create namespace for demo apps
resource "kubernetes_namespace" "demo_apps" {
  metadata {
    name = "pomerium-demo-apps"
    labels = {
      purpose = "demo-applications"
    }
  }
}

# Deploy Verify Service
resource "helm_release" "verify" {
  name       = "verify"
  namespace  = kubernetes_namespace.demo_apps.metadata[0].name
  chart      = "../../../../verify/helm/verify"
  
  values = [<<-EOT
    replicaCount: 2
    image:
      repository: pomerium/verify
      tag: latest
    service:
      type: ClusterIP
      port: 80
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  EOT
  ]
}

# Configure Pomerium with demo-friendly settings
resource "kubernetes_manifest" "pomerium_config" {
  depends_on = [module.pomerium_enterprise]
  
  manifest = {
    apiVersion = "ingress.pomerium.io/v1"
    kind       = "Pomerium"
    metadata = {
      name      = "global"
      namespace = "pomerium-system"
    }
    spec = {
      authenticate = {
        url = "https://authenticate.${local.domain}"
      }
      identityProvider = {
        provider = var.idp_provider
        secret   = kubernetes_secret.idp_secret.metadata[0].name
      }
      storage = {
        postgres = {
          secret = "pomerium-enterprise-database"
        }
      }
      # Demo-specific settings
      settings = {
        # Enable debug logging for demo
        log_level = "debug"
        
        # Set cookie settings for demo
        cookie_name     = "_pomerium_demo"
        cookie_domain   = local.domain
        cookie_secure   = true
        cookie_httpOnly = true
        
        # Demo timeout settings
        timeout_read  = "30s"
        timeout_write = "30s"
        timeout_idle  = "5m"
      }
    }
  }
}

# IDP Secret
resource "kubernetes_secret" "idp_secret" {
  metadata {
    name      = "idp-secret"
    namespace = "pomerium-system"
  }
  
  data = {
    client_id     = var.idp_client_id
    client_secret = var.idp_client_secret
  }
}

# Create demo SSH target VM
resource "google_compute_instance" "ssh_demo" {
  name         = "${local.cluster_name}-ssh-demo"
  machine_type = "e2-micro"
  zone         = local.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }
  
  network_interface {
    network    = google_compute_network.demo_vpc.name
    subnetwork = google_compute_subnetwork.demo_subnet.name
    
    access_config {
      # Ephemeral public IP
    }
  }
  
  metadata_startup_script = file("${path.module}/scripts/ssh-target-init.sh")
  
  tags = ["ssh-demo-target"]
  
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
  
  labels = {
    environment = "demo"
    purpose     = "ssh-proxy-demo"
  }
}

# Firewall rule for SSH access from cluster
resource "google_compute_firewall" "ssh_from_cluster" {
  name    = "${local.cluster_name}-ssh-from-pods"
  network = google_compute_network.demo_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.1.0.0/16"]  # Pod CIDR
  target_tags   = ["ssh-demo-target"]
}

# Deploy demo applications
module "demo_apps" {
  source = "./modules/demo-apps"
  
  namespace = kubernetes_namespace.demo_apps.metadata[0].name
  domain    = local.domain
}

# Create ingresses for demo apps
resource "kubernetes_ingress_v1" "verify" {
  metadata {
    name      = "verify"
    namespace = kubernetes_namespace.demo_apps.metadata[0].name
    annotations = {
      "ingress.pomerium.io/policy" = jsonencode([
        {
          allow = {
            or = [
              { domain = { is = "pomerium.com" } },
              { domain = { is = "pomerium.io" } },
              { email = { ends_with = "@pomerium.com" } }
            ]
          }
        }
      ])
      "ingress.pomerium.io/allow_public_unauthenticated_access" = "true"
      "ingress.pomerium.io/pass_identity_headers" = "true"
    }
  }
  
  spec {
    ingress_class_name = "pomerium"
    
    rule {
      host = "verify.${local.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "verify"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Output demo access information
output "demo_urls" {
  value = {
    console           = "https://console.${local.domain}"
    verify            = "https://verify.${local.domain}"
    grafana           = "https://grafana.${local.domain}"
    hello_world       = "https://hello.${local.domain}"
    ssh_demo_internal = google_compute_instance.ssh_demo.network_interface[0].network_ip
  }
}

output "setup_instructions" {
  value = <<-EOT
    Demo Environment Setup Instructions:
    
    1. Configure DNS:
       Point *.${local.domain} to ${google_compute_address.pomerium_lb.address}
    
    2. Access the demo:
       - Verify Service: https://verify.${local.domain}
       - Console: https://console.${local.domain}
       - SSH Demo: ssh -o ProxyCommand='pomerium-cli tcp --listen stdio ssh.${local.domain}:22' demo@localhost
    
    3. Demo credentials:
       - SSH: username 'demo', password 'pomerium-demo'
       - Console: Use administrator emails configured
  EOT
}