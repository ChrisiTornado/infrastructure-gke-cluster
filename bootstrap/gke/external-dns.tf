resource "google_service_account" "external_dns" {
  account_id   = "${var.name_prefix}-external-dns-sa"
  display_name = "Service Account for ExternalDNS"
  project      = var.project_id
}

resource "google_project_iam_member" "external_dns_admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_service_account_iam_member" "external_dns_workload_identity" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
}

output "external_dns_sa_email" {
  value       = google_service_account.external_dns.email
  description = "ExternalDNS GCP service account email for Workload Identity annotation"
}
