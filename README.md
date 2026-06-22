# infrastructure-gke-cluster

OpenTofu (Terraform-compatible) IaC for provisioning the GKE platform cluster on Google Cloud. This repository covers Day 1 bootstrapping: VPC, GKE cluster, node pool, IAM/Workload Identity, and the ArgoCD installation that hands over control to the GitOps repository.

## Overview

After `tofu apply` completes, the cluster is fully provisioned and ArgoCD is running. From that point on, all further cluster changes are managed via the GitOps repository.

**Domain:** `crypto-haven.fhbgl.study`  
**Region / Zone:** `europe-west4` / `europe-west4-a`

Related repositories:
- [gitops-gke](https://github.com/Toerbi1/gitops-gke) — ArgoCD GitOps manifests for all cluster workloads

## Repository Structure

```
.
├── bootstrap/
│   └── gke/
│       ├── cluster.tf        # GKE cluster (Workload Identity, ADVANCED_DATAPATH, release channel)
│       ├── node_pool.tf      # Spot node pool with autoscaling (min 1, max 2 × e2-standard-2)
│       ├── vpc.tf            # VPC + subnet (10.10.0.0/24)
│       ├── sa-gcs-reader.tf  # Workload Identity service account
│       ├── variables.tf      # Input variables
│       ├── outputs.tf        # Cluster name, zone, kubeconfig command
│       ├── terraform.tf      # Required providers and versions
│       ├── provider.tf       # Google provider configuration
│       └── .tflint.hcl       # TFLint rules
└── .github/
    └── workflows/
        └── validate.yml      # CI: fmt check, tflint, tofu validate
```

## Prerequisites

| Tool | Version |
|------|---------|
| `gcloud` CLI | latest |
| `opentofu` | >= 1.12 |
| `kubectl` | >= 1.35 |
| `tflint` | latest |

**GCP setup:**

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

## Provisioning the Cluster

Create a `terraform.tfvars` file in `bootstrap/gke/` (this file is gitignored):

```hcl
project_id = "your-gcp-project-id"
```

Then apply:

```bash
cd bootstrap/gke/

tofu init
tofu plan
tofu apply

# Configure kubectl
$(tofu output -raw kubernetes_cluster_gcloud_command)

# Verify
kubectl get nodes
```

## Infrastructure Details

| Resource | Configuration |
|----------|--------------|
| Cluster | Zonal (`europe-west4-a`), release channel `REGULAR` |
| Node pool | Spot instances, `e2-standard-2`, autoscaling 1–2 nodes |
| Networking | Custom VPC, `ADVANCED_DATAPATH` (eBPF/Cilium) |
| Workload Identity | Enabled — no static service account keys |
| Disk | `pd-balanced`, 32 GB per node |

Spot instances are used to minimise cost. The autoscaler scales to 2 nodes under load and back to 1 at idle.

## CI Pipeline

Every pull request targeting `bootstrap/**` runs:
1. `tofu fmt -check` — formatting check
2. `tflint` — lint with the GCP plugin
3. `tofu init -backend=false` + `tofu validate` — syntax validation

Validation steps (`fmt`, `tflint`, `tofu validate`) run without cloud credentials (`-backend=false`). Applying the IaC requires local GCP credentials (`gcloud auth application-default login`).

## Teardown

```bash
cd bootstrap/gke/
tofu destroy
```
