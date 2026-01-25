# DevOps CI/CD Pipeline with AWS EKS

A production-ready CI/CD pipeline for deploying applications to AWS EKS with comprehensive security scanning, policy enforcement, and GitOps-based deployment using ArgoCD.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Jobs](#pipeline-jobs)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Setup](#infrastructure-setup)
- [Pipeline Configuration](#pipeline-configuration)
- [Deployment Workflow](#deployment-workflow)
- [Security & Compliance](#security--compliance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project implements a complete DevOps CI/CD pipeline that addresses common challenges in AWS, Kubernetes (EKS), Terraform, Docker, and container deployments. The pipeline automates the entire software delivery lifecycle from code commit to production deployment.

### Key Features

- ✅ **Infrastructure as Code**: Complete Terraform modules for AWS EKS, VPC, and ECR
- ✅ **GitHub Actions CI/CD Pipeline**: Automated multi-stage pipeline with security scanning
- ✅ **Security Scanning**: Snyk SAST and container image vulnerability scanning
- ✅ **Policy Enforcement**: Kyverno policies for Kubernetes security and compliance
- ✅ **GitOps Deployment**: ArgoCD for declarative, automated deployments
- ✅ **Multi-Environment**: Separate configurations for dev, qa, and prod
- ✅ **Production-Ready**: Health checks, resource limits, autoscaling, and monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub Actions CI/CD Pipeline                  │
├─────────────────────────────────────────────────────────────────┤
│ Job 1: Platform Check → EKS Cluster Health Validation           │
│ Job 2: Validate → Dockerfile, K8s, Kyverno, Snyk SAST          │
│ Job 3: Build → Maven Artifact Generation                        │
│ Job 4: Package → Docker Image + Helm Chart → ECR               │
│ Job 5: Scan → Snyk Container Vulnerability Scan                │
│ Job 6: Promote → Update Config Repo → ArgoCD Deployment        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Infrastructure                          │
├─────────────────────────────────────────────────────────────────┤
│  VPC → EKS Cluster → Worker Nodes                               │
│  ECR → Container Images + Helm Charts                           │
│  ArgoCD → Config Repo → Automated Deployments                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Pipeline Jobs

### Job 1: Platform Check

Validates that the target EKS cluster is operational before deployment.

**Checks:**
- EKS cluster status is ACTIVE
- Worker nodes exist and are in Ready state
- Critical system pods are running (kube-system namespace)

**Script:** [`scripts/check-eks-cluster.sh`](scripts/check-eks-cluster.sh)

### Job 2-5: Validation

**Job 2: Validate Dockerfile** - Hadolint linting  
**Job 3: Validate Kubernetes** - Kubeconform manifest validation  
**Job 4: Validate Kyverno Policies** - Security policy testing  
**Job 5: SAST Snyk** - Code vulnerability scanning  

**Script:** [`scripts/validate-k8s-manifests.sh`](scripts/validate-k8s-manifests.sh)

### Job 6: Build Maven

Compiles Java application and generates JAR/WAR artifacts.

### Job 7-8: Package

**Job 7: Package Docker**
- Build Docker image from [`Dockerfile`](Dockerfile)
- Tag with commit SHA and environment
- Push to AWS ECR

**Job 8: Package Helm**
- Package Helm chart with version metadata
- Push to AWS ECR

### Job 9: Container Scan

Snyk scans built image for security vulnerabilities and CVEs.

### Job 10: Promote to ArgoCD

Updates GitOps config repository for ArgoCD deployment.

**Script:** [`scripts/update-config-repo.sh`](scripts/update-config-repo.sh)

### Job 11: Approval Gates

Manual approvals for QA and Production deployments.

## 📦 Prerequisites

### Required Tools

- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **kubectl** >= 1.28
- **Helm** >= 3.0
- **Docker** >= 24.0
- **Maven** >= 3.8
- **Git** >= 2.0

### Required Accounts & Credentials

- AWS account with EKS, ECR, VPC permissions
- GitHub account with Actions enabled
- Snyk account and API token
- ArgoCD installation on target clusters

### GitHub Secrets Configuration

Set these in **Settings → Secrets and variables → Actions**:

```
AWS_ACCOUNT_ID           # Your 12-digit AWS account ID
AWS_ACCESS_KEY_ID        # IAM access key
AWS_SECRET_ACCESS_KEY    # IAM secret key
SNYK_TOKEN              # Snyk API token
JENKINS_URL             # (Optional) Jenkins server URL
JENKINS_USER            # (Optional) Jenkins username
JENKINS_TOKEN           # (Optional) Jenkins API token
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/suresh-subramanian2013/SRE-Project-1-AWS-EKS-Argocd.git
cd SRE-Project-1-AWS-EKS-Argocd
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Create S3 bucket for state (one-time setup)
aws s3 mb s3://terraform-state-cicd-pipeline --region us-east-1

# Plan infrastructure
terraform plan -var="environment=dev"

# Apply infrastructure
terraform apply -var="environment=dev"

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name cicd-pipeline-dev
```

### 3. Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 4. Install Kyverno

```bash
# Install Kyverno
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.10.0/install.yaml

# Apply custom policies
kubectl apply -f kyverno-policies/
```

### 5. Deploy ArgoCD Applications

```bash
# Apply ArgoCD application definitions
kubectl apply -f argocd/application-dev.yaml
kubectl apply -f argocd/application-qa.yaml
kubectl apply -f argocd/application-prod.yaml
```

### 6. Configure GitHub Secrets

1. Go to repository **Settings → Secrets and variables → Actions**
2. Add all required secrets (see Prerequisites section)
3. Push code to `dev`, `qa`, or `prod` branch
4. Workflow automatically triggers!

## 🏗️ Infrastructure Setup

### Terraform Modules

#### VPC Module

Creates a production-ready VPC with:
- 3 public subnets across availability zones
- 3 private subnets for EKS worker nodes
- NAT gateways for outbound internet access
- EKS-specific tags for load balancer provisioning

#### EKS Module

Provisions an AWS EKS cluster with:
- Managed node groups with autoscaling
- OIDC provider for IRSA support
- Essential add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- CloudWatch logging for control plane

#### ECR Module

Creates ECR repositories with:
- Scan-on-push enabled for security
- Lifecycle policies (retain last 30 images)
- Encryption at rest (AES256)

### Customization

Edit [`terraform/variables.tf`](terraform/variables.tf):

```hcl
variable "environment" {
  default = "dev"
}

variable "eks_cluster_version" {
  default = "1.28"
}

variable "node_groups" {
  default = {
    general = {
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
    }
  }
}
```

## ⚙️ Pipeline Configuration

### GitHub Actions Secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ACCOUNT_ID` | AWS account ID | `123456789012` |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `SNYK_TOKEN` | Snyk API token | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `JENKINS_URL` | Jenkins server | `https://jenkins.example.com` |
| `JENKINS_USER` | Jenkins user | `ci-user` |
| `JENKINS_TOKEN` | Jenkins API token | `your-token` |

### Customize Pipeline

Edit [`.github/workflows/cicd-pipeline.yml`](.github/workflows/cicd-pipeline.yml) to:
- Add custom validation steps
- Modify security thresholds
- Add integration tests
- Configure notifications

## 🔄 Deployment Workflow

### Development Environment
- **Trigger:** Push to `dev` branch
- **Deployment:** Automatic
- **ArgoCD Sync:** Automatic

### QA Environment
- **Trigger:** Push to `qa` branch
- **Deployment:** Manual approval required
- **Tests:** Jenkins integration

### Production Environment
- **Trigger:** Push to `prod` branch
- **Deployment:** Manual approval required
- **ArgoCD Sync:** Manual (for safety)

## 🔒 Security & Compliance

### Kyverno Policies

1. **Restrict Privileged Containers** - Prevents privileged pods
2. **Require Resource Limits** - Enforces CPU/memory limits
3. **Disallow Host Namespaces** - Prevents host PID/IPC/network access

### Snyk Security Scanning

- **SAST (Job 5):** Source code vulnerability scanning
- **Container Scan (Job 9):** Docker image CVE scanning
- **Threshold:** High severity blocks pipeline

### Docker Security

The [`Dockerfile`](Dockerfile) implements:
- Non-root user execution
- Multi-stage builds
- Minimal base image (JRE slim)
- Health checks
- No unnecessary privileges

## 🐛 Troubleshooting

### Common Issues

#### EKS Cluster Not Ready
```bash
aws eks describe-cluster --name cicd-pipeline-dev --region us-east-1
```

#### Worker Nodes Not Ready
```bash
kubectl get nodes
kubectl describe node <node-name>
```

#### Dockerfile Validation Failed
Update `Dockerfile` to pin package versions:
```dockerfile
RUN apt-get update && apt-get install -y curl=7.68.0-1 && rm -rf /var/lib/apt/lists/*
```

#### Snyk Scan Failures
```bash
mvn versions:display-dependency-updates
```

#### ArgoCD Not Syncing
```bash
argocd app sync cicd-demo-app-dev
```

For detailed troubleshooting, see [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## 📁 Project Structure

```
sre-project-1/
├── .github/workflows/              # GitHub Actions
│   └── cicd-pipeline.yml          # Main CI/CD workflow
├── terraform/                      # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       └── ecr/
├── helm-chart/                     # Kubernetes Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── kyverno-policies/               # Security policies
├── argocd/                         # ArgoCD applications
├── scripts/                        # Helper scripts
├── src/                            # Sample Java app
├── Dockerfile                      # Container image
├── pom.xml                         # Maven config
└── README.md                       # This file
```

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 📧 Support

For questions or issues:
- Create an issue in the repository
- Contact: devops@example.com

---

**Built with ❤️ by the DevOps Team**
