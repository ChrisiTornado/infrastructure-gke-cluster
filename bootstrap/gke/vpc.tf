resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-cluster-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name_prefix}-cluster-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}
