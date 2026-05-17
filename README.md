# infrastructure-engineering-first-gke-cluster

# GKE Testing Cluster — Terraform + Helm Setup

A complete guide to provisioning a GKE cluster for testing and deploying **cert-manager** and **external-dns** via Helm charts.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| `gcloud` CLI | latest | https://cloud.google.com/sdk/docs/install |
| `opentofu` | >= 1.12 | https://opentofu.org/docs/intro/install/ |
| `kubectl` | >= 1.35 | https://kubernetes.io/docs/tasks/tools/ |

**GCP setup:**

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

---

## Repository Structure

```
.
├── bootstrap/
│   └── gke/
│       ├── main.tf           # GKE cluster + node pool
│       ├── variables.tf      # Input variables
│       ├── outputs.tf        # Cluster name, endpoint, kubeconfig cmd
│       ├── versions.tf       # Required providers & versions
│       └── terraform.tfvars  # Your values (gitignored)
├── helm/
│   ├── argo-cd/
│   │   └── values.yaml   # cert-manager Helm overrides
└── README.md
```

---

## Terraform — GKE Cluster


Add the `terraform.tfvars` file to bootstrap/gke folder

```hcl
project_id   = "your-gcp-project-id"
region       = "us-central1"
```

### Apply Terraform

```bash
cd bootstrap/gke/

tofu init
tofu plan
tofu apply

# Configure kubectl
$(tofu output -raw kubeconfig_command)

# Verify
kubectl get nodes
```
### Teaddown

```bash
cd bootstrap/gke/

tofu destroy
```