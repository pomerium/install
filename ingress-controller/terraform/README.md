This Terraform module installs the Pomerium Ingress Controller.

Docs: https://www.pomerium.com/docs/deploying/k8s/install

```terraform
module "pomerium_ingress_controller" {
    source = "git:https://github.com/pomerium/install//ingress-controller/terraform?ref=REF"
}
```

Where `REF` may be an individual commit, a branch (i.e. `main`) or version tag (i.e. `v0.28.0`).

