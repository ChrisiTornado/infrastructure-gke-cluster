variable "project_id" {
  description = "project id"
  type        = string
}

variable "name_prefix" {
  description = "Prefix name for the resources"
  type        = string
  default     = "inenp-"
}

variable "region" {
  description = "region"
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "zone"
  type        = string
  default     = "europe-west4-a"
}

variable "k8s_namespace" {
  description = "kubernetes namespace"
  type        = string
  default     = "default"
}

variable "k8s_service_account_name" {
  description = "kubernetes service account name"
  type        = string
  default     = "gcs-reader"
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 2
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-standard-2"
}