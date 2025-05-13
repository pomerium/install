terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      # Specify a version constraint if desired, e.g., "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0" // Matches version used in the underlying modules
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" // Used by the recipe
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "kubernetes" {
  // This example assumes you are running Terraform from an environment
  // that is already authenticated to your GKE cluster (e.g., via `gcloud container clusters get-credentials`).
  // Terraform will use the current context from your kubeconfig file.
  // For more explicit configuration, you can use a data source to fetch cluster details:
  /*
  data "google_client_config" "default" {}

  data "google_container_cluster" "primary" {
    name     = "your-gke-cluster-name" # Replace with your GKE cluster name
    location = var.gcp_region          # Or specific zone if applicable
    project  = var.gcp_project
  }

  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  */
}

variable "gcp_project" {
  type        = string
  description = "The GCP project ID where the GKE cluster and other resources are located."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region where the GKE cluster and other resources are located (e.g., us-central1)."
}

variable "domain" {
  type        = string
  description = "The DNS domain to use for Pomerium Enterprise ingresses (e.g., example.com)."
}

variable "administrators" {
  type        = list(string)
  description = "List of email addresses for initial Pomerium Enterprise administrators."
  default     = []
}

variable "license_key" {
  type        = string
  description = "Your Pomerium Enterprise license key."
  sensitive   = true
}

variable "image_registry_password" {
  type        = string
  description = "Password for the Pomerium Enterprise image registry (docker.cloudsmith.io)."
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "A prefix used for naming GCP resources created by the recipe (e.g., Cloud SQL instance)."
  default     = "pomerium-gke"
}

# You can add other variables from the recipe here if you want to override their defaults.
# For example:
# variable "db_tier" {
#   type        = string
#   description = "The tier of the Cloud SQL database instance."
#   default     = "db-f1-micro" # Default from the recipe
# }

module "pomerium_enterprise_gke" {
  source = "../../../recipe/ingress-controller-enterprise-terraform-gke"

  # Required variables
  gcp_project             = var.gcp_project
  gcp_region              = var.gcp_region
  domain                  = var.domain
  license_key             = var.license_key
  image_registry_password = var.image_registry_password
  administrators          = var.administrators

  # Optional variables (using defaults or custom values)
  prefix = var.prefix
  # db_tier                 = var.db_tier # Uncomment to use the variable defined above

  # The recipe expects the Kubernetes provider to be passed explicitly.
  providers = {
    kubernetes = kubernetes
    # The google provider is implicitly available to the recipe.
  }
}

# The recipe itself does not define outputs for DNS names directly.
# These would typically be derived from your `var.domain` input and the
# standard naming convention (pomerium-console.<domain>, pomerium-console-api.<domain>).
# You would then create DNS records pointing to the LoadBalancer IP of the pomerium-proxy service.

output "pomerium_enterprise_console_suggested_dns" {
  description = "Suggested DNS hostname for the Pomerium Enterprise Console. You need to create a DNS record pointing to the Pomerium proxy LoadBalancer IP."
  value       = "pomerium-console.${var.domain}"
}

output "pomerium_enterprise_console_api_suggested_dns" {
  description = "Suggested DNS hostname for the Pomerium Enterprise Console API. You need to create a DNS record pointing to the Pomerium proxy LoadBalancer IP."
  value       = "pomerium-console-api.${var.domain}"
}

output "cloud_sql_instance_name" {
  description = "Name of the Cloud SQL instance created for Pomerium Enterprise."
  value       = module.pomerium_enterprise_gke.cloud_sql_instance_name
}
