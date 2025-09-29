variable "namespace_name" {
  description = "The name of the namespace to create"
  type        = string
  default     = "pomerium-enterprise"
}

variable "use_external_namespace" {
  description = "Skip creating the namespace, assume it already exists, and use the provided namespace name"
  type        = bool
  default     = false
}

variable "image_name" {
  description = "Container image name"
  type        = string
  default     = "pomerium/enterprise/pomerium-console"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "v0.30.4"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

variable "image_pull_secret" {
  description = "Name of the Docker registry secret"
  type        = string
  default     = "pomerium-enterprise-docker-registry"
}

variable "image_registry" {
  description = "Image registry"
  type        = string
  default     = "docker.cloudsmith.io"
}

variable "image_registry_username" {
  description = "Docker registry username"
  type        = string
  default     = "pomerium/enterprise"
}

variable "image_registry_password" {
  description = "Docker registry password"
  type        = string
}

variable "tolerations" {
  description = "List of tolerations for the pods."
  type = list(object({
    key                = optional(string)
    operator           = optional(string, "Equal")
    value              = optional(string)
    effect             = optional(string)
    toleration_seconds = optional(number)
  }))
  default = []
}

variable "audience" {
  description = "List of audiences. By default would be derived from the ingress DNS names."
  type        = list(string)
  default     = []
}

variable "administrators" {
  description = "List of administrators (emails). this should only be used for the console bootstrap."
  type        = list(string)
  default     = []
}

variable "core_namespace_name" {
  description = "The name of the namespace Pomerium Core was deployed to"
  type        = string
  default     = "pomerium-ingress-controller"
}

variable "database_url" {
  description = "Postgres database DSN string, may be either URL or key-value format"
  type        = string
}

variable "license_key" {
  description = "Pomerium license key"
  type        = string
  sensitive   = true
}

variable "resources_limits_cpu" {
  description = "Resource CPU limits for the container"
  type        = string
  default     = "4"
}

variable "resources_limits_memory" {
  description = "Resource RAM limits for the container"
  type        = string
  default     = "10Gi"
}

variable "resources_requests_cpu" {
  description = "Resource CPU requests for the container"
  type        = string
  default     = "2"
}

variable "resources_requests_memory" {
  description = "Resource RAM requests for the container"
  type        = string
  default     = "4Gi"
}

variable "resources_ephemeral_storage" {
  description = "Resource ephemeral storage for the container"
  type        = string
  default     = "4Gi"
}

variable "deployment_replicas" {
  description = "Number of replicas for the Pomerium Enterprise Deployment"
  type        = number
  default     = 1
}

variable "service_account_annotations" {
  description = "Name of the service account"
  type        = map(string)
  default     = {}
}

variable "sidecars" {
  description = "Additional sidecar containers to run in the pod"
  type = list(object({
    name  = string
    image = string
    args  = list(string)
  }))
}

variable "license_key_validate_offline" {
  description = "Whether to validate the license key offline. Can only be used with a valid offline license key."
  type        = bool
  default     = false
}

variable "console_ingress" {
  description = "Console Ingress configuration. Set to null to disable."
  type = object({
    dns         = string
    annotations = map(string)
  })
}

variable "console_api_ingress" {
  description = "Console API Ingress configuration. Annotations should contain the Pomerium policy. Set to null to disable."
  type = object({
    dns         = string
    annotations = map(string)
  })
}

variable "ingress_class_name" {
  description = "Name of the Ingress class"
  type        = string
  default     = "pomerium"
}

variable "bootstrap_secret" {
  description = "Reference to the core bootstrap secret to copy shared secrets from"
  type = object({
    name      = string
    namespace = string
  })
}

variable "prometheus_url" {
  description = "URL of the Prometheus server to query for metrics"
  type        = string
  default     = ""
}

variable "validation_mode" {
  description = "Validation mode for the Pomerium Enterprise deployment"
  type        = string
  default     = "full"
  validation {
    condition     = contains(["disabled", "static", "full"], var.validation_mode)
    error_message = "validation_mode must be one of 'disabled', 'static', or 'full'"
  }
}

variable "bootstrap_service_account" {
  description = "Enable a bootstrap service account that may be used by the Terraform Provider to complete the console configuration."
  type        = bool
  default     = false
}

variable "use_clustered_databroker" {
  description = "Setup a separate cluster of databroker nodes in clustered mode."
  type        = bool
  default     = false
}

variable "clustered_databroker_cluster_size" {
  description = "The number of nodes for the clustered databroker."
  type        = number
  default     = 3
}
