# DevOps CI/CD Pipeline with AWS EKS

A production-ready CI/CD pipeline for deploying applications to AWS EKS with comprehensive security scanning, policy enforcement, and GitOps-based deployment using ArgoCD.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
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
- ✅ **6-Stage CI/CD Pipeline**: Platform checks, validation, build, package, scan, and promote
- ✅ **Security Scanning**: Snyk SAST and container image vulnerability scanning
- ✅ **Policy Enforcement**: Kyverno policies for Kubernetes security and compliance
- ✅ **GitOps Deployment**: ArgoCD for declarative, automated deployments
- ✅ **Multi-Environment**: Separate configurations for dev, qa, and prod
- ✅ **Production-Ready**: Health checks, resource limits, autoscaling, and monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Actions CI/CD Pipeline               │
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
│                         AWS Infrastructure                       │
├─────────────────────────────────────────────────────────────────┤
│  VPC (Public/Private Subnets) → EKS Cluster → Worker Nodes     │
│  ECR Repositories → Container Images + Helm Charts              │
│  ArgoCD → Monitors Config Repo → Deploys to EKS                │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Pipeline Stages

### Stage 1: Platform Checks (AWS EKS Cluster)

Validates that the target EKS cluster is operational before deployment.

**Checks:**
- EKS cluster status is ACTIVE
- Worker nodes exist and are in Ready state
- Critical system pods are running (kube-system namespace)

**Script:** [`scripts/check-eks-cluster.sh`](scripts/check-eks-cluster.sh)

### Stage 2: Validate

Ensures code quality, security, and compliance before building.

**Components:**
- **Dockerfile Linting**: Hadolint validates Dockerfile best practices
- **Kubernetes Syntax**: Kubeconform validates K8s manifests
- **Kyverno Policies**: Tests security policies (privileged pods, resource limits)
- **Snyk SAST**: Static application security testing for code vulnerabilities

**Script:** [`scripts/validate-k8s-manifests.sh`](scripts/validate-k8s-manifests.sh)

### Stage 3: Build Artifact (Maven)

Compiles the Java application and generates deployable artifacts.

**Output:** JAR/WAR files stored as pipeline artifacts

### Stage 4: Package

Containerizes the application and prepares for deployment.

**Actions:**
1. Build Docker image from [`Dockerfile`](Dockerfile)
2. Tag image with commit SHA and environment
3. Package Helm chart with version metadata
4. Push image and chart to AWS ECR

**Metadata Example:** `${AWS_ECR_URI}:${COMMIT_ID}`

### Stage 5: Scan Container Image with Snyk

Scans the built container image for security vulnerabilities.

**Checks:**
- Known CVE IDs in software packages
- Outdated libraries and risky dependencies
- Security issues in base images

**Threshold:** High severity vulnerabilities

### Stage 6: Promote to Dev/QA/Prod

Updates the GitOps configuration repository for ArgoCD deployment.

**Workflow:**
1. Create/update `config.yaml` with Helm chart version and image tag
2. Commit and push to config repository
3. ArgoCD detects changes and syncs to target cluster
4. Post-deployment validation (health checks, pod status)
5. Run automated tests (Jenkins integration for QA/Prod)

**Script:** [`scripts/update-config-repo.sh`](scripts/update-config-repo.sh)

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

- AWS account with permissions for EKS, ECR, VPC, IAM
- GitHub account with repository access
- Snyk account and API token
- ArgoCD installation on target clusters

### Environment Variables

Set these in GitHub Secrets (Settings → Secrets and variables → Actions):

```bash
AWS_ACCOUNT_ID=123456789012
AWS_DEFAULT_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
SNYK_TOKEN=your-snyk-api-token
JENKINS_URL=https://jenkins.example.com
JENKINS_USER=ci-user
JENKINS_TOKEN=your-jenkins-token
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/sre-project-1.git
cd sre-project-1
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Create S3 bucket for state (one-time setup)
aws s3 mb s3://terraform-state-cicd-pipeline --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

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

### 6. Configure GitHub Actions

1. Push code to GitHub repository
2. Set secrets in GitHub repository settings (Settings → Secrets and variables → Actions)
3. Pipeline will automatically trigger on commits to `dev`, `qa`, or `prod` branches

## 🏗️ Infrastructure Setup

### Terraform Modules

#### VPC Module (`terraform/modules/vpc/`)

Creates a production-ready VPC with:
- 3 public subnets across availability zones
- 3 private subnets for EKS worker nodes
- NAT gateways for outbound internet access
- EKS-specific tags for load balancer provisioning

#### EKS Module (`terraform/modules/eks/`)

Provisions an AWS EKS cluster with:
- Managed node groups with autoscaling
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Essential add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- CloudWatch logging for control plane

#### ECR Module (`terraform/modules/ecr/`)

Creates ECR repositories with:
- Scan-on-push enabled for security
- Lifecycle policies (retain last 30 images)
- Encryption at rest (AES256)

### Customization

Edit [`terraform/variables.tf`](terraform/variables.tf) to customize:

```hcl
variable "environment" {
  default = "dev"  # Change to qa or prod
}

variable "eks_cluster_version" {
  default = "1.28"  # Update Kubernetes version
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

Configure in **Settings → Secrets and variables → Actions**:

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ACCOUNT_ID` | AWS account ID | `123456789012` |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `SNYK_TOKEN` | Snyk API token | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `JENKINS_URL` | Jenkins server URL | `https://jenkins.example.com` |
| `JENKINS_USER` | Jenkins username | `ci-user` |
| `JENKINS_TOKEN` | Jenkins API token | `your-jenkins-token` |

### Customizing Pipeline Jobs

Edit [`.github/workflows/cicd-pipeline.yml`](.github/workflows/cicd-pipeline.yml) to:

- Add custom validation steps
- Modify security thresholds
- Add integration tests
- Configure notifications

## 🔄 Deployment Workflow

### Development Environment

```mermaid
graph LR
    A[Commit to dev] --> B[Pipeline Triggers]
    B --> C[All 6 Stages Run]
    C --> D[Auto-deploy to Dev]
    D --> E[ArgoCD Syncs]
    E --> F[Pods Running]
```

**Trigger:** Push to `dev` branch  
**Deployment:** Automatic

### QA Environment

**Trigger:** Push to `qa` branch  
**Deployment:** Manual approval required  
**Tests:** Jenkins automated tests run post-deployment

### Production Environment

**Trigger:** Push to `prod` branch  
**Deployment:** Manual approval required  
**ArgoCD Sync:** Manual (for safety)

### Promotion Flow

1. **Dev** → Code merged, auto-deployed
2. **QA** → Manual promotion, automated tests
3. **Prod** → Manual promotion after QA approval

## 🔒 Security & Compliance

### Kyverno Policies

Three cluster policies enforce security:

1. **Restrict Privileged Containers** ([`kyverno-policies/restrict-privileged-pods.yaml`](kyverno-policies/restrict-privileged-pods.yaml))
   - Prevents privileged containers
   - Severity: High

2. **Require Resource Limits** ([`kyverno-policies/require-resource-limits.yaml`](kyverno-policies/require-resource-limits.yaml))
   - Enforces CPU and memory limits
   - Severity: Medium

3. **Disallow Host Namespaces** ([`kyverno-policies/disallow-host-namespaces.yaml`](kyverno-policies/disallow-host-namespaces.yaml))
   - Prevents host PID, IPC, and network access
   - Severity: High

### Snyk Security Scanning

- **SAST (Stage 2):** Scans source code for vulnerabilities
- **Container Scan (Stage 5):** Scans Docker images for CVEs
- **Threshold:** High severity blocks pipeline

### Docker Security

The [`Dockerfile`](Dockerfile) implements security best practices:
- Non-root user execution
- Multi-stage builds
- Minimal base image (JRE slim)
- Health checks
- No unnecessary privileges

## 🐛 Troubleshooting

### Common Issues

#### 1. EKS Cluster Not Ready

**Error:** `EKS cluster is not ACTIVE`

**Solution:**
```bash
# Check cluster status
aws eks describe-cluster --name cicd-pipeline-dev --region us-east-1

# Check CloudFormation stacks
aws cloudformation describe-stacks --region us-east-1
```

#### 2. Worker Nodes Not Ready

**Error:** `Some worker nodes are not in Ready state`

**Solution:**
```bash
# Check node status
kubectl get nodes

# Describe problematic node
kubectl describe node <node-name>

# Check node group in AWS console
aws eks describe-nodegroup --cluster-name cicd-pipeline-dev --nodegroup-name <nodegroup-name>
```

#### 3. Dockerfile Validation Failed

**Error:** `hadolint: DL3008: Pin versions in apt-get install`

**Solution:** Update Dockerfile to pin package versions:
```dockerfile
RUN apt-get update && apt-get install -y \
    curl=7.68.0-1ubuntu2.14 \
    && rm -rf /var/lib/apt/lists/*
```

#### 4. Kyverno Policy Violation

**Error:** `Privileged containers are not allowed`

**Solution:** Update Helm chart [`values.yaml`](helm-chart/values.yaml):
```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

#### 5. Snyk Scan Failures

**Error:** `High severity vulnerabilities found`

**Solution:**
```bash
# Update dependencies in pom.xml
mvn versions:display-dependency-updates

# Or adjust threshold in .github/workflows/cicd-pipeline.yml
SNYK_SEVERITY_THRESHOLD: "critical"
```

#### 6. ArgoCD Not Syncing

**Error:** `Application health status is Degraded`

**Solution:**
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View detailed status
kubectl describe application cicd-demo-app-dev -n argocd

# Force sync
argocd app sync cicd-demo-app-dev
```

#### 7. ECR Push Failed

**Error:** `denied: Your authorization token has expired`

**Solution:**
```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
```

### Detailed Troubleshooting Guide

For more detailed troubleshooting steps, see [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## 📁 Project Structure

```
sre-project-1/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Root configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── backend.tf                 # S3 backend config
│   └── modules/
│       ├── vpc/                   # VPC module
│       ├── eks/                   # EKS cluster module
│       └── ecr/                   # ECR repositories module
├── helm-chart/                    # Helm chart for application
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── serviceaccount.yaml
│       └── hpa.yaml
├── kyverno-policies/              # Kubernetes security policies
│   ├── restrict-privileged-pods.yaml
│   ├── require-resource-limits.yaml
│   └── disallow-host-namespaces.yaml
├── argocd/                        # ArgoCD application definitions
│   ├── application-dev.yaml
│   ├── application-qa.yaml
│   └── application-prod.yaml
├── scripts/                       # Pipeline helper scripts
│   ├── check-eks-cluster.sh      # Stage 1: Platform check
│   ├── validate-k8s-manifests.sh # Stage 2: Validation
│   └── update-config-repo.sh     # Stage 6: Promotion
├── src/                           # Sample Java application
│   └── main/
│       ├── java/com/example/App.java
│       └── resources/application.properties
├── .github/
│   └── workflows/
│       └── cicd-pipeline.yml      # GitHub Actions CI/CD pipeline
├── Dockerfile                     # Container image definition
├── pom.xml                        # Maven build configuration
└── README.md                      # This file
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 📧 Support

For questions or issues:
- Create an issue in the repository
- Contact the DevOps team at devops@example.com

---

**Built with ❤️ by the DevOps Team**
#   S R E - P r o j e c t - 1 - A W S - E K S - A r g o c d  
 