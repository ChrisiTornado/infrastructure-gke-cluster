# infrastructure-engineering-first-gke-cluster

# GKE Testing Cluster — Terraform + Helm Setup

A complete guide to provisioning a GKE cluster for testing and deploying **cert-manager** and **external-dns** via Helm charts.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Structure](#repository-structure)
3. [Terraform — GKE Cluster](#terraform--gke-cluster)
4. [Helm — cert-manager](#helm--cert-manager)
5. [Helm — external-dns](#helm--external-dns)
6. [Teardown](#teardown)

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| `gcloud` CLI | latest | https://cloud.google.com/sdk/docs/install |
| `terraform` | >= 1.6 | https://developer.hashicorp.com/terraform/install |
| `kubectl` | >= 1.28 | https://kubernetes.io/docs/tasks/tools/ |
| `helm` | >= 3.14 | https://helm.sh/docs/intro/install/ |

**GCP setup:**

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

---

## Repository Structure

```
.
├── terraform/
│   ├── main.tf           # GKE cluster + node pool
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Cluster name, endpoint, kubeconfig cmd
│   ├── versions.tf       # Required providers & versions
│   └── terraform.tfvars  # Your values (gitignored)
├── helm/
│   ├── cert-manager/
│   │   └── values.yaml   # cert-manager Helm overrides
│   └── external-dns/
│       └── values.yaml   # external-dns Helm overrides
└── README.md
```

---

## Terraform — GKE Cluster

### `terraform/versions.tf`

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
```

### `terraform/variables.tf`

```hcl
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "test-cluster"
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-standard-2"
}
```

### `terraform/main.tf`

```hcl
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # Remove the default node pool and manage it separately
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enables Workload Identity (required for cert-manager + external-dns GCP auth)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Minimal logging/monitoring for a test cluster (reduces cost)
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      env = "test"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
```

### `terraform/outputs.tf`

```hcl
output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "kubeconfig_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
```

### `terraform/terraform.tfvars`

```hcl
project_id   = "your-gcp-project-id"
region       = "us-central1"
cluster_name = "test-cluster"
node_count   = 1
machine_type = "e2-standard-2"
```

> ⚠️ Add `terraform.tfvars` to `.gitignore` — it contains project-specific values.

### Apply Terraform

```bash
cd terraform/

terraform init
terraform plan
terraform apply

# Configure kubectl
$(terraform output -raw kubeconfig_command)

# Verify
kubectl get nodes
```

---

## Helm — cert-manager

cert-manager automates TLS certificate issuance (e.g. via Let's Encrypt).

### Add the Helm repository

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

### `helm/cert-manager/values.yaml`

```yaml
# Install CRDs automatically
crds:
  enabled: true

# Replica count (1 is fine for testing)
replicaCount: 1

# Enable Prometheus metrics (optional)
prometheus:
  enabled: false

# Workload Identity annotation — required for DNS-01 challenges on GCP
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: cert-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Install cert-manager

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.5 \
  --values helm/cert-manager/values.yaml

# Verify pods are running
kubectl get pods -n cert-manager
```

### Create a ClusterIssuer (Let's Encrypt staging)

```yaml
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - http01:
          ingress:
            class: nginx
```

```bash
kubectl apply -f cluster-issuer.yaml
kubectl get clusterissuer
```

> For production, replace `letsencrypt-staging` with `https://acme-v02.api.letsencrypt.org/directory`.

---

## Helm — external-dns

external-dns syncs Kubernetes Ingress/Service hostnames to your DNS provider automatically.

### Add the Helm repository

```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update
```

### `helm/external-dns/values.yaml`

```yaml
# Use Google Cloud DNS as provider
provider:
  name: google

# GCP project where your Cloud DNS zone lives
env:
  - name: EXTERNAL_DNS_GOOGLE_PROJECT
    value: "YOUR_PROJECT_ID"

# Limit external-dns to specific DNS zones (recommended)
domainFilters:
  - example.com

# Only manage records created by external-dns (safe for shared zones)
policy: sync

# Sync interval
interval: 1m

# Workload Identity annotation
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: external-dns@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Log level (debug is helpful for testing)
logLevel: debug
```

### Install external-dns

```bash
helm install external-dns external-dns/external-dns \
  --namespace external-dns \
  --create-namespace \
  --version 1.14.4 \
  --values helm/external-dns/values.yaml

# Verify
kubectl get pods -n external-dns
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
```

### GCP IAM — Workload Identity bindings

Both cert-manager and external-dns need GCP service accounts bound via Workload Identity:

```bash
# --- cert-manager ---
gcloud iam service-accounts create cert-manager \
  --project=YOUR_PROJECT_ID

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:cert-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

gcloud iam service-accounts add-iam-policy-binding \
  cert-manager@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:YOUR_PROJECT_ID.svc.id.goog[cert-manager/cert-manager]"

# --- external-dns ---
gcloud iam service-accounts create external-dns \
  --project=YOUR_PROJECT_ID

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:external-dns@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

gcloud iam service-accounts add-iam-policy-binding \
  external-dns@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:YOUR_PROJECT_ID.svc.id.goog[external-dns/external-dns]"
```

---

## Teardown

```bash
# Uninstall Helm releases
helm uninstall cert-manager -n cert-manager
helm uninstall external-dns -n external-dns

# Delete namespaces
kubectl delete namespace cert-manager external-dns

# Destroy GKE cluster
cd terraform/
terraform destroy
```

---

## Quick Reference

| Component | Namespace | Helm Repo | Chart |
|-----------|-----------|-----------|-------|
| cert-manager | `cert-manager` | `jetstack` | `jetstack/cert-manager` |
| external-dns | `external-dns` | `external-dns` | `external-dns/external-dns` |

**Useful commands:**

```bash
# Check cert-manager webhook
kubectl get validatingwebhookconfigurations

# Watch certificate issuance
kubectl get certificate -A -w

# Check external-dns sync status
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f
```