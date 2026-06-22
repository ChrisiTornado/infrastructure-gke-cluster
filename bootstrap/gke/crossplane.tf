resource "google_service_account" "crossplane" {
  account_id   = "crossplane"
  display_name = "Crossplane Workload Identity SA"
  project      = var.project_id
}

resource "google_project_iam_member" "crossplane_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/compute.networkAdmin",
    "roles/cloudsql.admin",
    "roles/servicenetworking.networksAdmin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.crossplane.email}"
}

resource "google_service_account_iam_member" "crossplane_workload_identity" {
  service_account_id = google_service_account.crossplane.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/crossplane]"
}

output "crossplane_sa_email" {
  value       = google_service_account.crossplane.email
  description = "Crossplane GCP service account email"
}
