resource "google_service_account" "cert_manager" {
  account_id   = "${var.name_prefix}-cert-manager-sa"
  display_name = "Service Account for cert-manager"
  project      = var.project_id
}

resource "google_project_iam_member" "cert_manager_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cert_manager.email}"
}

resource "google_service_account_iam_member" "cert_manager_workload_identity" {
  service_account_id = google_service_account.cert_manager.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
}

output "cert_manager_sa_email" {
  value       = google_service_account.cert_manager.email
  description = "cert-manager GCP service account email for Workload Identity annotation"
}
