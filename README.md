# CliXX Retail — Base Infrastructure

This pipeline provisions everything AWS needs before the application can be deployed. Run this first. The deployment pipeline depends on the outputs this writes to S3.

---

## Before You Run This

- Terraform >= 1.3.0 installed
- S3 bucket `mystatefile-clixxretail` already exists
- Jenkins has these credentials saved:
  - `github-token`
  - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

---

## What Gets Created

- VPC with public and private subnets across 2 availability zones
- Internet Gateway and NAT Gateway so the worker nodes can reach the internet
- Security groups for the EKS control plane and worker nodes
- IAM roles for the cluster, node group, and ALB Controller
- ECR repository where the deployment pipeline pushes Docker images
- EKS cluster running Kubernetes 1.29
- Node group running `t3.medium` instances in the private subnets
- OIDC provider so the ALB Controller can assume an IAM role
- AWS Load Balancer Controller installed via Helm — this is what creates the ALB when the deployment pipeline applies the ingress

---

## File Structure

```
base_infra/
├── Jenkinsfile
├── provider.tf
├── variables.tf
├── vpc.tf
├── security_groups.tf
├── iam.tf
├── ecr.tf
├── eks.tf
├── outputs.tf
└── README.md
```

---

## Remote State

| Setting | Value |
|---|---|
| S3 Bucket | `mystatefile-clixxretail` |
| State Key | `eks/base_infra/terraform.tfstate` |
| Region | `us-east-1` |

---

## What the Deployment Pipeline Reads from This State

| Output | How it's used |
|---|---|
| `cluster_name` | Connects kubectl to the right cluster |
| `ecr_repository_url` | Docker tag, push, and image injection into deployment.yaml |
| `aws_account_id` | Constructs the ECR login endpoint |
| `vpc_id` | Reference |
| `private_subnet_ids` | Where the worker nodes are placed |
| `public_subnet_ids` | Where the NAT Gateway and ALB are placed |

---

## Pipeline Stages

```
Checkout → Terraform Init → Terraform Plan → Terraform Apply
```

---

## Running It Manually

```bash
cd base_infra
terraform init
terraform plan
terraform apply
```