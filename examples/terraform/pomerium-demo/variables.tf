variable "pomerium_license_key" {
  type        = string
  description = "Pomerium Enterprise license key"
  sensitive   = true
}

variable "pomerium_registry_password" {
  type        = string
  description = "Password for Pomerium Enterprise registry (docker.cloudsmith.io)"
  sensitive   = true
}

variable "demo_administrators" {
  type        = list(string)
  description = "List of administrator emails for the demo environment"
  default     = ["demo@pomerium.com"]
}

variable "idp_provider" {
  type        = string
  description = "Identity provider for the demo (google, github, okta, etc.)"
  default     = "google"
}

variable "idp_client_id" {
  type        = string
  description = "OAuth client ID for the identity provider"
  sensitive   = true
}

variable "idp_client_secret" {
  type        = string
  description = "OAuth client secret for the identity provider"
  sensitive   = true
}

variable "allowed_email_domains" {
  type        = list(string)
  description = "Email domains allowed to access the demo"
  default     = ["pomerium.com", "pomerium.io"]
}

variable "demo_features" {
  type = object({
    enable_tcp_proxy    = bool
    enable_device_trust = bool
    enable_groups       = bool
    enable_metrics      = bool
  })
  description = "Feature flags for demo functionality"
  default = {
    enable_tcp_proxy    = true
    enable_device_trust = false
    enable_groups       = true
    enable_metrics      = true
  }
}