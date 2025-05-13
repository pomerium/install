terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0" // Matches version used in the core module
    }
  }
}

provider "kubernetes" {
  // Configure your Kubernetes provider.
  // If your KUBECONFIG environment variable is set, or if you are running
  // this from a machine with ~/.kube/config correctly set up,
  // Terraform should automatically use it.
  // Otherwise, you might need to specify:
  // config_path    = "~/.kube/config"
  // config_context = "your-cluster-context"
}

module "pomerium_ingress_controller" {
  source = "../../../ingress-controller/terraform"

  // --- Example Customizations ---

  // To deploy into a different namespace:
  // namespace_name = "custom-pomerium-namespace"

  // To enable the databroker (for features like TCP proxying or if not using external storage):
  // enable_databroker = true

  // To set specific resource requests/limits for the controller:
  // resources_requests_cpu    = "200m"
  // resources_requests_memory = "128Mi"
  // resources_limits_cpu      = "1000m"
  // resources_limits_memory   = "512Mi"

  // For a full list of configurable variables, see the module's variables.tf file
  // at ../../../ingress-controller/terraform/variables.tf
}

output "bootstrap_secret_name" {
  description = "Name of the Pomerium bootstrap secret."
  value       = module.pomerium_ingress_controller.bootstrap_secret.name
}

output "bootstrap_secret_namespace" {
  description = "Namespace of the Pomerium bootstrap secret."
  value       = module.pomerium_ingress_controller.bootstrap_secret.namespace
}

output "ingress_class_name" {
  description = "Name of the IngressClass created by the module."
  value       = module.pomerium_ingress_controller.ingress_class_name
}
