This Terraform module installs 

```terraform
provider "kubernetes" {

}

module "pomerium_ingress_controller" {
    source = "git:https://github.com/pomerium/install//ingress-controller/terraform?ref=REF"
}
```

Where `REF` may be an individual commit, a branch (i.e. `main`) or version tag (i.e. `v0.27.2`).

Once Pomerium Ingress Controller is installed, you may reference additional configurations via the `Pomerium` CRD.
See https://www.pomerium.com/docs/k8s/configure

As it has to reference a CRD that does not exist until installed, the configuration manifest has to be created part of a separate Terraform run. 

```terraform
resource "kubernetes_manifest" "pomerium_config" {
    manifest = {
        apiVersion = "ingress.pomerium.io/v1"
        kind = "Pomerium"
        metadata = {
            name = "global"
        }
        spec = {
            secrets = "pomerium-ingress-controller/bootstrap"
        }
    }
}
```
