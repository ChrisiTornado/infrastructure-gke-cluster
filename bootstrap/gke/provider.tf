data "google_client_config" "default" {}

provider "google" {
  # set environment variable GOOGLE_APPLICATION_CREDENTIALS to the path of your service account key file (you can store it in this directory named gcp-sa-key.json which is gitignored)

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "github" {
  owner = var.gitops_repo_owner
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
  }
}
