variable "gcp_region" {
  type        = string
  description = "The region where the resources will be created"
  default     = "us-central1"
}

variable "gcp_project" {
  type        = string
  description = "The GCP project where the resources will be created"
}

variable "license_key" {
  type        = string
  description = "The license key for the enterprise installation"
}

variable "domain" {
  type        = string
  description = "The DNS domain to use for the installation"
}

variable "administrators" {
  type        = list(string)
  description = "The list of administrators for the enterprise installation"
}

variable "image_registry_password" {
  type        = string
  description = "The password for the image registry"
}

variable "db_tier" {
  type        = string
  description = "The tier of the database"
  default     = "db-f1-micro"
}

variable "prefix" {
  type        = string
  description = "Prefix to add to all cloud resources for uniqueness"
  default     = "prod"
}

variable "ingress_controller_image_tag" {
  type        = string
  description = "The image tag for the ingress controller"
  default     = "main"
}

variable "pomerium_enterprise_image_tag" {
  type        = string
  description = "The image tag for the enterprise installation"
  default     = "main"
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
