resource "kubectl_manifest" "pomerium_crd" {
  count     = var.install_crds ? 1 : 0
  yaml_body = file("${path.module}/crd.yaml")
}
