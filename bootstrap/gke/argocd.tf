locals {
  argocd_namespace = "argocd"
  gitops_repo_url  = var.gitops_repo_url != "" ? var.gitops_repo_url : "git@github.com:${var.gitops_repo_owner}/${var.gitops_repo_name}.git"
}

resource "tls_private_key" "argocd_gitops_deploy_key" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "argocd_gitops_read_only" {
  count = var.create_gitops_deploy_key ? 1 : 0

  title      = var.gitops_deploy_key_title
  repository = var.gitops_repo_name
  key        = tls_private_key.argocd_gitops_deploy_key.public_key_openssh
  read_only  = true
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = local.argocd_namespace
  }

  depends_on = [
    google_container_node_pool.node_pool
  ]
}

resource "kubernetes_secret_v1" "argocd_gitops_repository" {
  metadata {
    name      = "gitops-repository"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type          = "git"
    url           = local.gitops_repo_url
    sshPrivateKey = tls_private_key.argocd_gitops_deploy_key.private_key_openssh
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  atomic  = true
  timeout = 600

  values = [
    templatefile("${path.module}/argocd-values.yaml.tftpl", {
      argocd_hostname           = var.argocd_hostname
      argocd_ingress_class_name = var.argocd_ingress_class_name
      gitops_repo_url           = local.gitops_repo_url
      gitops_root_path          = var.gitops_root_path
      gitops_target_revision    = var.gitops_target_revision
    })
  ]

  depends_on = [
    github_repository_deploy_key.argocd_gitops_read_only,
    kubernetes_secret_v1.argocd_gitops_repository
  ]
}
