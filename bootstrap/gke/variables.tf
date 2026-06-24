variable "project_id" {
  description = "project id"
  type        = string
}

variable "name_prefix" {
  description = "Prefix name for the resources"
  type        = string
  default     = "inenp"
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

variable "argocd_chart_version" {
  description = "Pinned version of the official argo/argo-cd Helm chart."
  type        = string
  default     = "9.5.17"
}

variable "argocd_hostname" {
  description = "Public hostname for the ArgoCD UI ingress."
  type        = string
}

variable "argocd_ingress_class_name" {
  description = "IngressClass used for the ArgoCD UI ingress."
  type        = string
  default     = "gce"
}

variable "gitops_repo_owner" {
  description = "GitHub owner or organization for the GitOps repository."
  type        = string
}

variable "gitops_repo_name" {
  description = "Name of the GitOps repository that ArgoCD will reconcile."
  type        = string
}

variable "gitops_repo_url" {
  description = "SSH URL for the GitOps repository."
  type        = string
  default     = ""
}

variable "gitops_target_revision" {
  description = "Git revision ArgoCD should track for the root Application."
  type        = string
  default     = "main"
}

variable "gitops_root_path" {
  description = "Path in the GitOps repository that contains the app-of-apps Application manifests."
  type        = string
  default     = "apps"
}

variable "create_gitops_deploy_key" {
  description = "Whether Terraform should register the generated ArgoCD deploy key on the GitOps GitHub repository."
  type        = bool
  default     = true
}

variable "gitops_deploy_key_title" {
  description = "Title of the read-only deploy key that Terraform creates on the GitOps GitHub repository."
  type        = string
  default     = "argocd-gke-bootstrap"
}
