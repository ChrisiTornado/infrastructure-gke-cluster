output "project_id" {
  value       = var.project_id
  description = "Project ID where the cluster is deployed"
}
output "zone" {
  value       = var.zone
  description = "Zone where the cluster is deployed"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.cluster.name
  description = "Cluster Name"
}

output "kubernetes_cluster_gcloud_command" {
  value       = "KUBECONFIG=./gke.kubeconfig gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --zone ${var.zone} --project ${var.project_id}"
  description = "Command to get credentials for the cluster"
}

output "argocd_url" {
  value       = "https://${var.argocd_hostname}"
  description = "ArgoCD UI URL exposed through the configured ingress"
}

output "gitops_repo_url" {
  value       = local.gitops_repo_url
  description = "GitOps repository URL used by the root ArgoCD Application"
}

output "argocd_gitops_deploy_key_public" {
  value       = tls_private_key.argocd_gitops_deploy_key.public_key_openssh
  description = "Public half of the read-only deploy key used by ArgoCD"
}
