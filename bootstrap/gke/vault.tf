# KMS Key Ring — a container that groups related keys together
resource "google_kms_key_ring" "vault" {
  name     = "${var.name_prefix}-vault-keyring"
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.services]
}

# KMS Crypto Key — the actual key Vault uses for auto-unseal
resource "google_kms_crypto_key" "vault_unseal" {
  name            = "vault-unseal-key"
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

# Service Account for Vault pod
resource "google_service_account" "vault" {
  account_id   = "${var.name_prefix}-vault-sa"
  display_name = "Service Account for Vault"
  project      = var.project_id
}

# Give Vault SA permission to use KMS key
resource "google_kms_crypto_key_iam_member" "vault_kms_roles" {
  for_each = toset([
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/cloudkms.viewer",
  ])

  crypto_key_id = google_kms_crypto_key.vault_unseal.id
  role          = each.value
  member        = "serviceAccount:${google_service_account.vault.email}"
}

# Workload Identity binding — links Vault K8s SA to GCP SA
resource "google_service_account_iam_member" "vault_workload_identity" {
  service_account_id = google_service_account.vault.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[vault/vault]"
}

output "vault_kms_key_ring" {
  value       = google_kms_key_ring.vault.name
  description = "KMS key ring name for Vault auto-unseal"
}

output "vault_kms_crypto_key" {
  value       = google_kms_crypto_key.vault_unseal.name
  description = "KMS crypto key name for Vault auto-unseal"
}

output "vault_sa_email" {
  value       = google_service_account.vault.email
  description = "Vault GCP service account email"
}

resource "local_file" "vault_helm_values" {
  content = templatefile("${path.module}/vault-values.tftpl", {
    vault_sa_email       = google_service_account.vault.email
    project_id           = var.project_id
    region               = var.region
    vault_kms_key_ring   = google_kms_key_ring.vault.name
    vault_kms_crypto_key = google_kms_crypto_key.vault_unseal.name
  })
  filename = "${path.module}/../../helm/vault/values.yaml"
}
