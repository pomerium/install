output "configure_kubectl" {
  value = <<-EOT
    To configure kubectl, run:
    ${output.kubectl_config_command.value}
    
    Or use the following provider configuration in Terraform:
    
    provider "kubernetes" {
      host                   = "https://${output.cluster_endpoint.value}"
      token                  = output.access_token.value
      cluster_ca_certificate = base64decode(output.cluster_ca_certificate.value)
    }
  EOT
  description = "Instructions to configure kubectl"
}

output "ssh_target_info" {
  value = var.enable_ssh_vm ? <<-EOT
    SSH Target VM Information:
    - External IP: ${output.ssh_vm_external_ip.value}
    - Internal IP: ${output.ssh_vm_internal_ip.value}
    - Username: pomerium-demo
    - Password: demo-password
    
    This VM is accessible from within the cluster and can be used
    as a target for Pomerium SSH proxying demonstrations.
  EOT : "SSH VM not enabled"
  description = "Information about the SSH target VM"
}