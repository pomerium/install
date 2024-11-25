provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "random" {}
