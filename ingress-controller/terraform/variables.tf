# Installation Customization
variable "namespace_name" {
  description = "The name of the namespace to create"
  type        = string
  default     = "pomerium-ingress-controller"
}

variable "use_external_namespace" {
  description = "Skip creating the namespace, assume it already exists, and use the provided namespace name"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "pomerium-ingress-controller"
  }
}

variable "pod_labels" {
  description = "Labels to apply to pods"
  type        = map(string)
  default     = {}
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
  default     = "pomerium/ingress-controller"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "v0.29.2"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

variable "controller_service_account_name" {
  description = "Name of the controller service account"
  type        = string
  default     = "pomerium-ingress-controller"
}

variable "gen_secrets_service_account_name" {
  description = "Name of the gen-secrets service account"
  type        = string
  default     = "pomerium-ingress-controller-gen-secrets"
}

variable "controller_cluster_role_name" {
  description = "Name of the controller cluster role"
  type        = string
  default     = "pomerium-ingress-controller"
}

variable "gen_secrets_cluster_role_name" {
  description = "Name of the gen-secrets cluster role"
  type        = string
  default     = "pomerium-ingress-controller-gen-secrets"
}

variable "deployment_name" {
  description = "Name of the Deployment"
  type        = string
  default     = "pomerium-ingress-controller"
}

variable "deployment_replicas" {
  description = "Number of replicas for the Deployment"
  type        = number
  default     = 1
}

variable "resources_requests_cpu" {
  description = "CPU requests for the Deployment"
  type        = string
  default     = "300m"
}

variable "resources_requests_memory" {
  description = "Memory requests for the Deployment"
  type        = string
  default     = "200Mi"
}

variable "resources_limits_cpu" {
  description = "CPU limits for the Deployment"
  type        = string
  default     = "5000m"
}

variable "resources_limits_memory" {
  description = "Memory limits for the Deployment"
  type        = string
  default     = "1Gi"
}

variable "proxy_service_type" {
  description = "Type of the Proxy Service"
  type        = string
  default     = "LoadBalancer"
}

variable "ingress_class_name" {
  description = "Name of the IngressClass"
  type        = string
  default     = "pomerium"
}

variable "service_account_labels" {
  description = "Labels to apply to service accounts"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "pomerium-ingress-controller"
  }
}

variable "cluster_role_labels" {
  description = "Labels to apply to cluster roles"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "pomerium-ingress-controller"
  }
}

variable "service_labels" {
  description = "Labels to apply to services"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "pomerium-ingress-controller"
  }
}

variable "deployment_labels" {
  description = "Labels to apply to the deployment"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "pomerium-ingress-controller"
  }
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

variable "job_name" {
  description = "Name of the Job"
  type        = string
  default     = "pomerium-gen-secrets"
}

variable "pomerium_config_name" {
  description = "Name of the Pomerium CRD"
  type        = string
  default     = "global"
}

variable "enable_databroker" {
  description = "Enable the databroker"
  type        = bool
  default     = false
}

variable "proxy_port_https" {
  description = "Port for HTTPS"
  type        = number
  default     = 443
}

variable "proxy_port_http" {
  description = "Port for HTTP"
  type        = number
  default     = 80
}

variable "proxy_node_port_https" {
  description = "Node port for HTTPS, only used when proxy_service_type is NodePort"
  type        = number
  default     = null
}

variable "proxy_node_port_http" {
  description = "Host port for HTTP"
  type        = number
  default     = null
}

variable "node_selector" {
  description = "Node selector for the Deployment"
  type        = map(string)
  default     = {}
}

variable "config" {
  description = "Pomerium configuration. Set to null to disable config creation. See https://www.pomerium.com/docs/k8s/reference"
  type = object({
    accessLogFields = optional(list(string))
    authenticate = optional(object({
      callbackPath = optional(string)
      url          = string
    }))
    caSecrets    = optional(list(string))
    certificates = optional(list(string))
    cookie = optional(object({
      domain   = optional(string)
      expire   = optional(string)
      httpOnly = optional(bool)
      name     = optional(string)
      sameSite = optional(string)
    }))
    identityProvider = optional(object({
      provider            = string
      requestParams       = optional(map(string))
      requestParamsSecret = optional(string)
      scopes              = optional(list(string))
      secret              = string
      url                 = optional(string)
    }))
    jwtClaimHeaders             = optional(map(string))
    passIdentityHeaders         = optional(bool)
    programmaticRedirectDomains = optional(string)
    runtimeFlags                = optional(map(bool))
    storage = optional(object({
      postgres = object({
        caSecret  = optional(string)
        secret    = string
        tlsSecret = optional(string)
      })
    }))
    timeouts = optional(object({
      idle   = optional(string)
      read   = optional(string)
      write  = optional(string)
    }))
    otel = optional(object({
      endpoint              = string                 # required
      protocol              = string                 # required
      headers               = optional(map(string))
      timeout               = optional(string)
      sampling              = optional(number)
      resourceAttributes    = optional(map(string))
      bspScheduleDelay      = optional(string)
      bspMaxExportBatchSize = optional(number)
      logLevel              = optional(string)
    }))
    useProxyProtocol = optional(bool)
  })
  default = {}
}

variable "rolling_update" {
  description = "Rolling update configuration"
  type = object({
    max_surge       = optional(string)
    max_unavailable = optional(string)
  })
  default = {
    max_surge       = "25%"
    max_unavailable = "25%"
  }
}

variable "secrets_version" {
  description = "Version of the secrets. Changing this will cause the secrets to be regenerated."
  type        = number
  default     = 1
}
