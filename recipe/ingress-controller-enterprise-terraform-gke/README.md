module "pomerium_enterprise_gke" {
  source = "git::https://github.com/pomerium/install//recipe/ingress-controller-enterprise-terraform-gke"

  prefix                  = "prod"
  domain                  = "your wildcard domain name"
  license_key             = "pomerium enterprise license key"
  image_registry_password = "pomerium enterprise registry password (provided by Pomerium Sales)"
  gcp_project             = "your GCP project ID"
  administrators          = ["admin email"]
}
