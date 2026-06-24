locals {
  wi_pool = "${var.project_id}.svc.id.goog"
  crossplane = {
    namespace = "crossplane-system"
    sa_name   = "crossplane"
    # can only be added after crossplane has been installed
    members = []
  }
}

resource "google_service_account" "crossplane" {
  project      = var.project_id
  account_id   = "crossplane"
  display_name = "Crossplane Workload Identity SA"
}

resource "google_project_iam_member" "crossplane" {
  for_each = toset([
      "roles/cloudsql.admin",
      "roles/iam.editor",
      "roles/compute.editor",
      "roles/container.editor",
      "roles/servicenetworking.editor",
      "roles/servicenetworking.networksAdmin",
      "roles/databasecenter.admin",
      "roles/cloudsql.instanceUser",
      "roles/iam.workloadIdentityPoolAdmin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.crossplane.email}"
}

resource "google_service_account_iam_member" "crossplane_compute_wi" {
  for_each = toset(local.crossplane.members)

  service_account_id = google_service_account.crossplane.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.wi_pool}[${local.crossplane.namespace}/${each.value}]"
}

output "crossplane_gsa_email" {
  value = google_service_account.crossplane.email
}