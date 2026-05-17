resource "google_container_cluster" "cluster" {
  name        = "demo-gke-cluster"
  description = "My Cluster"
  location    = var.zone

  release_channel {
    channel = "REGULAR"
  }
  gke_auto_upgrade_config {
    patch_mode = "ACCELERATED"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  network           = google_compute_network.vpc.name
  subnetwork        = google_compute_subnetwork.subnet.name
  datapath_provider = "ADVANCED_DATAPATH"

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
      auto_monitoring_config {
        scope = "NONE"
      }
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  deletion_protection = false
}
