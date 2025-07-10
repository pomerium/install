This recipe installs Pomerium Ingress Controller and Pomerium Enterprise into an existing Kubernetes cluster.

```hcl
provider kubernetes {
  # configure your kubernetes provider
}

module "pomerium_enterprise_gke" {
  source = "git::https://github.com/pomerium/install//recipe/ingress-controller-enterprise-terraform-gke?ref=v0.30.0"

  prefix                  = "prod"
  domain                  = "your wildcard domain name"
  license_key             = "pomerium enterprise license key"
  image_registry_password = "pomerium enterprise registry password (provided by Pomerium Sales)"
  gcp_project             = "your GCP project ID"
  gcp_region              = "your GCP region, where the cluster is located"
  administrators          = ["admin@corp.com"]

  providers = {
    kubernetes = kubernetes
  }
}
```

