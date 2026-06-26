# infrastructure-gke-cluster

Bootstrap repository for a GKE cluster that installs ArgoCD through Terraform/OpenTofu. After the first IaC run, ArgoCD points to a separate GitOps repository and reconciles cluster workloads from Git.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| `gcloud` CLI | latest | https://cloud.google.com/sdk/docs/install |
| `opentofu` | >= 1.12 | https://opentofu.org/docs/intro/install/ |
| `kubectl` | >= 1.35 | https://kubernetes.io/docs/tasks/tools/ |
| GitHub token | repo admin scope for the GitOps repo | required only when Terraform creates the deploy key |

## GCP Setup

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

If you use a service account key, set `GOOGLE_APPLICATION_CREDENTIALS` to the key path.

## GitHub Setup

Terraform creates a read-only deploy key for the new GitOps repository and stores the private key as an ArgoCD repository Secret in the cluster.

Set a GitHub token before running `tofu apply`:

```bash
export GITHUB_TOKEN=YOUR_TOKEN
```

On Windows PowerShell:

```powershell
$env:GITHUB_TOKEN = "YOUR_TOKEN"
```

If the GitOps repository does not exist yet, create it first or set `create_gitops_deploy_key = false`, then add the `argocd_gitops_deploy_key_public` output manually as a read-only deploy key.

## Repository Structure

```text
.
├── bootstrap/
│   └── gke/
│       ├── argocd.tf                  # ArgoCD namespace, deploy key, repo secret, Helm release
│       ├── argocd-values.yaml.tftpl   # ArgoCD Helm values plus root Application
│       ├── cluster.tf                 # GKE cluster
│       ├── node_pool.tf               # GKE node pool
│       ├── provider.tf                # Google, GitHub, Kubernetes, Helm providers
│       ├── terraform.tf               # Required provider versions
│       ├── terraform.tfvars.example   # Example variable file
│       └── variables.tf               # Input variables
└── GITOPS_REPO_HANDOFF.md             # What to create in the separate GitOps repo
```

## Bootstrap Flow

1. Terraform creates the GKE cluster and node pool.
2. Terraform creates the `argocd` namespace.
3. Terraform generates an SSH deploy key.
4. Terraform registers the public key on the GitOps GitHub repository.
5. Terraform creates an ArgoCD repository Secret with the private key.
6. Terraform installs ArgoCD from the pinned `argo/argo-cd` Helm chart.
7. The ArgoCD Helm release creates a root `Application` named `root`.
8. The root Application reconciles `gitops/apps` from the separate GitOps repository.

## Configure Variables

Copy the example file and fill in real values:

```bash
cd bootstrap/gke
cp terraform.tfvars.example terraform.tfvars
```

Minimum required values:

```hcl
project_id = "your-gcp-project-id"

argocd_hostname = "argocd.example.com"

gitops_repo_owner = "your-github-user-or-org"
gitops_repo_name  = "your-new-gitops-repo"
```

## Apply

```bash
cd bootstrap/gke

tofu init
tofu plan
tofu apply
```

Configure `kubectl` after the cluster exists:

```bash
$(tofu output -raw kubernetes_cluster_gcloud_command)
kubectl get nodes
kubectl get pods -n argocd
kubectl get applications -n argocd
```

## Teardown

```bash
cd bootstrap/gke
tofu destroy
```

## Notes

- ArgoCD anonymous UI access is disabled.
- ArgoCD RBAC is enabled with read-only as the default role for authenticated users.
- The ArgoCD UI is exposed only through the configured GKE Ingress hostname.
- The ArgoCD chart version is pinned through `argocd_chart_version`.
- The generated private deploy key is stored in Terraform state. For production, source the key from a dedicated secret manager instead.
