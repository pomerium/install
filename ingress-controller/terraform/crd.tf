resource "kubectl_manifest" "pomerium_crd" {
  yaml_body = file("${path.module}/crd.yaml")
}

