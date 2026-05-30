data "google_container_engine_versions" "versions" {}

resource "google_service_account" "np_sa" {
  account_id   = "${var.name_prefix}-np-sa"
  display_name = "Service Account for the cluster"
}

resource "google_container_node_pool" "node_pool" {
  name_prefix    = "${var.name_prefix}-node-pool"
  cluster        = google_container_cluster.cluster.name
  location       = var.zone
  node_locations = [var.zone]

  version            = data.google_container_engine_versions.versions.release_channel_default_version["STABLE"]
  initial_node_count = var.min_node_count
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    spot         = true
    machine_type = var.machine_type

    boot_disk {
      disk_type = "pd-balanced"
      size_gb   = 32
    }

    service_account = google_service_account.np_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      role = "worker"
    }
  }
}
