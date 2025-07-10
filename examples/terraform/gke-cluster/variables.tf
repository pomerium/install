variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region for resources"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The GCP zone for zonal resources. If empty, regional cluster will be created"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster"
  default     = "pomerium-demo-cluster"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the primary subnet"
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  type        = string
  description = "CIDR range for pod IPs"
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  type        = string
  description = "CIDR range for service IPs"
  default     = "10.2.0.0/16"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "CIDR block for the master nodes"
  default     = "172.16.0.0/28"
}

variable "enable_private_nodes" {
  type        = bool
  description = "Enable private nodes (nodes without public IPs)"
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint (master nodes not accessible from public internet)"
  default     = false
}

variable "authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "List of authorized networks for master access"
  default = [{
    cidr_block   = "0.0.0.0/0"
    display_name = "all"
  }]
}

variable "node_count" {
  type        = number
  description = "Initial number of nodes"
  default     = 3
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes for autoscaling"
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes for autoscaling"
  default     = 5
}

variable "machine_type" {
  type        = string
  description = "Machine type for nodes"
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB for nodes"
  default     = 100
}

variable "preemptible_nodes" {
  type        = bool
  description = "Use preemptible nodes"
  default     = false
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable network policy addon"
  default     = true
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable binary authorization"
  default     = false
}

variable "enable_managed_prometheus" {
  type        = bool
  description = "Enable GKE managed Prometheus"
  default     = true
}

variable "release_channel" {
  type        = string
  description = "Release channel for GKE cluster"
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be RAPID, REGULAR, or STABLE"
  }
}

variable "node_labels" {
  type        = map(string)
  description = "Labels to apply to nodes"
  default = {
    environment = "demo"
    purpose     = "pomerium"
  }
}

variable "node_tags" {
  type        = list(string)
  description = "Network tags for nodes"
  default     = ["gke-node"]
}

variable "enable_ssh_vm" {
  type        = bool
  description = "Create an external VM for SSH demo"
  default     = true
}