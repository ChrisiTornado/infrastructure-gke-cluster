# infrastructure-gke-cluster

OpenTofu / Terraform-compatible infrastructure code for provisioning the GKE platform cluster on Google Cloud.

This repository bootstraps the platform infrastructure: VPC, GKE cluster, node pool, Workload Identity, ArgoCD, and the Google Cloud IAM/KMS prerequisites for platform components such as Vault, ExternalDNS, cert-manager, and Crossplane.

After `tofu apply`, ArgoCD takes over and reconciles cluster workloads from the GitOps repository.

## Related Repositories

* GitOps repository: https://github.com/Toerbi1/gitops-gke
* Backend repository: https://github.com/bhuang02/hochschule-burgenland-bswe-ws2024-2at-backend
* Frontend repository: https://github.com/bhuang02/burgenland-frontend

## Project Details

* Domain: `crypto-haven.fhbgl.study`
* Region: `europe-west4`
* Zone: `europe-west4-a`

## Repository Structure

```text
.
├── bootstrap/
│   └── gke/
│       ├── argocd.tf
│       ├── argocd-values.yaml.tftpl
│       ├── cert-manager.tf
│       ├── cluster.tf
│       ├── crossplane.tf
│       ├── external-dns.tf
│       ├── node_pool.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── sa-gcs-reader.tf
│       ├── terraform.tf
│       ├── terraform.tfvars.example
│       ├── variables.tf
│       ├── vault.tf
│       ├── vpc.tf
│       └── .tflint.hcl
├── helm/
│   └── vault/
│       └── Chart.yaml
└── .github/
    └── workflows/
        └── validate.yml
```

## Prerequisites

* `gcloud` CLI
* `opentofu >= 1.12.0`
* `kubectl`
* `tflint`
* GitHub token, if Terraform should configure access to the GitOps repository

## GCP Setup

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

## GitHub Setup

If GitOps repository access is configured by Terraform, set a GitHub token before applying:

```bash
export GITHUB_TOKEN=YOUR_TOKEN
```

PowerShell:

```powershell
$env:GITHUB_TOKEN = "YOUR_TOKEN"
```

## Configure Variables

Create a local `terraform.tfvars` file:

```bash
cd bootstrap/gke
cp terraform.tfvars.example terraform.tfvars
```

Minimum required values:

```hcl
project_id = "your-gcp-project-id"

argocd_hostname = "argocd.example.com"

gitops_repo_owner = "Toerbi1"
gitops_repo_name  = "gitops-gke"
```

## Apply

```bash
cd bootstrap/gke

tofu init
tofu plan
tofu apply
```

Configure `kubectl`:

```bash
$(tofu output -raw kubernetes_cluster_gcloud_command)
```

Verify:

```bash
kubectl get nodes
kubectl get pods -n argocd
kubectl get applications -n argocd
```

## What This Repository Creates

* GKE cluster
* GKE node pool
* VPC and subnet
* Workload Identity setup
* ArgoCD installation
* IAM prerequisites for Vault, ExternalDNS, cert-manager, and Crossplane
* KMS key for Vault auto-unseal

Application workloads are not managed directly in this repository. They are managed through the GitOps repository:

```text
https://github.com/Toerbi1/gitops-gke
```

The application source code lives in separate repositories:

```text
Backend:  https://github.com/bhuang02/hochschule-burgenland-bswe-ws2024-2at-backend
Frontend: https://github.com/bhuang02/burgenland-frontend
```

## CI Pipeline

Pull requests touching `bootstrap/**` run:

1. `tofu fmt -check`
2. `tflint`
3. `tofu init -backend=false`
4. `tofu validate`

## Teardown

```bash
cd bootstrap/gke
tofu destroy
```

## Documentation Note

This README was partially drafted with AI assistance and manually reviewed by the project team.

