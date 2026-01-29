# SRE-Project-2-DevSecOps-AWS-EKS-Jenkins-Argocd

A production-ready CI/CD pipeline for deploying applications to AWS EKS with comprehensive security scanning, policy enforcement, and GitOps-based deployment using ArgoCD.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Stages](#pipeline-stages)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Jenkins Setup](#jenkins-setup)
- [Infrastructure Setup](#infrastructure-setup)
- [Pipeline Configuration](#pipeline-configuration)
- [Deployment Workflow](#deployment-workflow)
- [Security & Compliance](#security--compliance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project implements a complete DevOps CI/CD pipeline using **Jenkins** that addresses common challenges in AWS, Kubernetes (EKS), Terraform, Docker, and container deployments. The pipeline automates the entire software delivery lifecycle from code commit to production deployment.

### Key Features

- ✅ **Infrastructure as Code**: Complete Terraform modules for AWS EKS, VPC, and ECR
- ✅ **Jenkins CI/CD Pipeline**: Declarative pipeline with security scanning and approvals
- ✅ **Security Scanning**: Snyk SAST and container image vulnerability scanning
- ✅ **Policy Enforcement**: Kyverno policies for Kubernetes security and compliance
- ✅ **GitOps Deployment**: ArgoCD for declarative, automated deployments
- ✅ **Multi-Environment**: Separate configurations for dev, qa, and prod
- ✅ **Production-Ready**: Health checks, resource limits, autoscaling, and monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Jenkins CI/CD Pipeline                      │
├─────────────────────────────────────────────────────────────────┤
│ Stage 1: Initialize → Environment Validation                    │
│ Stage 2: Platform Check → EKS Cluster Health                   │
│ Stage 3: Validate → Dockerfile, K8s, Kyverno, Snyk SAST       │
│ Stage 4: Build → Maven Artifact Generation                     │
│ Stage 5: Package → Docker Image + Helm Chart → ECR            │
│ Stage 6: Container Scan → Snyk Vulnerability Scan              │
│ Stage 7: Promote → Update Config Repo → ArgoCD Deployment     │
│ Stage 8: Approval Gates → Manual Approval (QA/Prod)           │
│ Stage 9: Verify → ArgoCD Sync Status                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  Infrastructure as Code Pipeline                 │
├─────────────────────────────────────────────────────────────────┤
│ Stage 1: Checkout → Git Repository                             │
│ Stage 2: Terraform Init → Backend Setup                        │
│ Stage 3: Terraform Validate → Syntax Check                     │
│ Stage 4: TFLint → Code Quality Scan                           │
│ Stage 5: tfsec → Security Scan                                │
│ Stage 6: Checkov → Compliance Scan                            │
│ Stage 7: Terraform Plan → Infrastructure Planning              │
│ Stage 8: Manual Approval → Apply or Destroy                    │
│ Stage 9: Terraform Apply/Destroy → Infrastructure Deploy       │
│ Stage 10: Update kubeconfig → Cluster Access                   │
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

## 🚀 Pipeline Stages - Application CI/CD

### Stage 1: Initialize

Validates environment branch matching and sets up build metadata.

**Checks:**
- Branch matches target environment (dev/qa/prod)
- Git metadata collection (commit, branch, timestamp)

### Stage 2: Platform Check

Validates that the target EKS cluster is operational before deployment.

**Checks:**
- EKS cluster status is ACTIVE
- Worker nodes exist and are in Ready state
- Critical system pods are running (kube-system namespace)

**Script:** [scripts/check-eks-cluster.sh](scripts/check-eks-cluster.sh)

### Stage 3: Validate (Parallel)

**Validate Dockerfile** - Hadolint linting  
**Validate Kubernetes** - kubeconform manifest validation  
**Validate Kyverno Policies** - Security policy testing  
**SAST Security Scan** - Snyk source code vulnerability scanning  

**Script:** [scripts/validate-k8s-manifests.sh](scripts/validate-k8s-manifests.sh)

### Stage 4: Build

Compiles Java application with Maven and generates JAR/WAR artifacts.

### Stage 5: Package (Parallel)

**Package Docker Image**
- Build Docker image from [Dockerfile](Dockerfile)
- Tag with commit SHA and environment
- Push to AWS ECR

**Package Helm Chart**
- Create Helm chart with application configuration
- Push to ECR Helm repository

### Stage 6: Container Scan

Scans Docker image for vulnerabilities using Snyk.

**Checks:**
- Base image vulnerabilities
- Application dependencies
- Container configuration issues

### Stage 7: Promote

Updates the configuration repository to trigger ArgoCD deployment.

**Actions:**
- Update Helm values in config repository
- Create/update application manifests
- Commit changes with build metadata

**Script:** [scripts/update-config-repo.sh](scripts/update-config-repo.sh)

### Stage 8: Approval Gates

Manual approval required for QA and production deployments.

**Dev**: Automatic approval  
**QA/Prod**: Manual approval required (24-hour timeout)

### Stage 9: Verify

Checks ArgoCD synchronization status and application health.

**Verifies:**
- ArgoCD application is synced
- All pods are running
- Readiness probes pass

## 🚀 IaC Pipeline Stages - Terraform Infrastructure

### Stage 1: Checkout
Clones the Git repository to get Terraform code.

### Stage 2: Terraform Init
Initializes working directory and downloads providers.

### Stage 3: Terraform Validate
Validates Terraform configuration syntax and structure.

### Stage 4: TFLint
Checks for Terraform best practices and coding standards.

### Stage 5: tfsec
Scans for security misconfigurations and compliance issues.

### Stage 6: Checkov
Performs compliance scanning against frameworks (CIS, PCI DSS, HIPAA, SOC 2).

### Stage 7: Terraform Plan
Generates infrastructure execution plan (tfplan).

### Stage 8: Manual Approval
Requires human approval for apply or destroy operations.

### Stage 9: Terraform Apply/Destroy
Applies planned changes or destroys infrastructure.

### Stage 10: Update kubeconfig
Updates kubeconfig after cluster creation.

## 📋 Prerequisites

### Local Development
- Git
- Docker 24.0+
- Docker Compose
- kubectl
- Helm 3+
- AWS CLI
- Terraform 1.0+
- Java 11+
- Maven 3.8+

### AWS Account
- AWS Account with IAM permissions
- EC2, ECS, EKS, VPC, IAM, ECR access
- S3 bucket for Terraform state
- Appropriate IAM roles and policies

### Jenkins Requirements
- Jenkins 2.361+ LTS
- 70+ plugins (see [jenkins/plugins.txt](jenkins/plugins.txt))
- AWS credentials configured
- Git repository access
- Kubernetes cluster access

## 🚀 Quick Start

### Option 1: Docker Compose (Local Development)

```bash
cd jenkins
docker-compose up -d

# Access Jenkins at http://localhost:8080
# Default credentials: admin / admin (change immediately)
```

### Option 2: Kubernetes Deployment

```bash
# Install Jenkins using Helm
helm repo add jenkinsci https://charts.jenkins.io
helm install jenkins jenkinsci/jenkins -f jenkins/values.yaml

# Access Jenkins via port-forward
kubectl port-forward svc/jenkins 8080:8080
```

### Option 3: Traditional Installation

```bash
# See jenkins/JENKINS_SETUP.md for detailed installation steps
```

## 🔧 Jenkins Setup

### 1. Configure Credentials

In Jenkins UI, go to **Manage Jenkins → Manage Credentials → Add Credentials**:

- **aws-account-id**: AWS Account ID (Secret text)
- **aws-access-key-id**: AWS Access Key (Secret text)
- **aws-secret-access-key**: AWS Secret Key (Secret text)
- **git-ssh-key**: SSH key for Git repository (SSH key)
- **docker-registry-credentials**: ECR login (Username/password)
- **github-token**: GitHub PAT (Secret text)

### 2. Create Pipeline Jobs

**Application Pipeline:**
```
Job: SRE-App-Pipeline
Type: Pipeline
Pipeline Definition: Pipeline script from SCM
SCM: Git (your repository)
Script Path: Jenkinsfile
```

**IaC Pipeline:**
```
Job: SRE-IaC-Pipeline
Type: Pipeline
Pipeline Definition: Pipeline script from SCM
SCM: Git (your repository)
Script Path: Jenkinsfile
```

### 3. Set Up Webhooks

Configure Git webhook to trigger Jenkins on push:
- **Webhook URL**: `http://jenkins-server/generic-webhook-trigger/invoke`
- **Trigger on**: Push events
- **Content type**: application/json

See [jenkins/JENKINS_SETUP.md](jenkins/JENKINS_SETUP.md) for complete setup guide.

## 🏗️ Infrastructure Setup

### 1. Configure Terraform

```bash
cd terraform

# Set AWS credentials
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_DEFAULT_REGION=us-east-1

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars << EOF
environment = "dev"
region = "us-east-1"
cluster_name = "sre-eks-cluster"
EOF

# Plan and apply
terraform plan
terraform apply
```

### 2. Deploy Applications

```bash
# Update ArgoCD config repository
./scripts/update-config-repo.sh

# Verify deployment
kubectl get pods -n default
kubectl get svc -n default
```

See [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for detailed steps.

## 📝 Pipeline Configuration

### Environment Variables

Create a `.env` file in project root:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# EKS Configuration
EKS_CLUSTER_NAME=sre-eks-cluster
EKS_REGION=us-east-1

# Docker Registry
DOCKER_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com

# Application Configuration
APP_NAME=sre-app
APP_VERSION=1.0.0
```

### Build Parameters

**ENVIRONMENT**: Choice (dev, qa, prod)
**SKIP_TESTS**: Boolean (false by default)
**SKIP_SECURITY_SCAN**: Boolean (false by default)
**DESTROY_INFRASTRUCTURE**: Boolean (false by default, IaC only)

## 🔄 Deployment Workflow

```
Developer commits code
        ↓
Git webhook triggers Jenkins
        ↓
Application Pipeline runs:
  - Build & Test
  - Security Scan
  - Package Docker & Helm
  - Container Scan
  - Approve (if QA/Prod)
        ↓
Configuration repository updated
        ↓
ArgoCD detects changes
        ↓
ArgoCD deploys to EKS
        ↓
Application running in cluster
        ↓
Health checks verified
```

## 🔒 Security & Compliance

### Security Scanning

- **SAST**: Snyk source code vulnerability scanning
- **Container**: Snyk container image scanning
- **Policy**: Kyverno policies for Kubernetes security
- **Infrastructure**: tfsec and Checkov for IaC security

### Policy Enforcement

Kyverno policies configured in [kyverno-policies/](kyverno-policies/):

- `disallow-host-namespaces.yaml` - Prevent host namespace access
- `require-resource-limits.yaml` - Enforce CPU/memory limits
- `restrict-privileged-pods.yaml` - Prevent privileged pod execution

### Approval Gates

- **Dev**: Automatic approval (continuous deployment)
- **QA**: Manual approval (1 day timeout)
- **Prod**: Manual approval (1 day timeout)

## 🛠️ Troubleshooting

### Jenkins Pipeline Fails

**Check:**
1. Jenkins logs: `docker logs jenkins-container`
2. Pipeline logs in Jenkins UI
3. AWS credentials configured correctly
4. Git repository access

**Debug:**
```bash
# Check Jenkins pod logs
kubectl logs -f -l app=jenkins

# Check pipeline job details
curl http://jenkins:8080/job/SRE-App-Pipeline/lastBuild/
```

### EKS Cluster Issues

```bash
# Check cluster status
aws eks describe-cluster --name sre-eks-cluster --region us-east-1

# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system
```

### ArgoCD Deployment Issues

```bash
# Check ArgoCD status
kubectl get applications -n argocd

# Check application sync status
argocd app get sre-app

# Check logs
argocd app logs sre-app
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed troubleshooting.

## 📚 Documentation

- [WALKTHROUGH.md](WALKTHROUGH.md) - Component walkthrough
- [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) - Implementation roadmap
- [JENKINS_QUICK_REFERENCE.md](JENKINS_QUICK_REFERENCE.md) - Jenkins quick start
- [JENKINS_SETUP.md](jenkins/JENKINS_SETUP.md) - Detailed Jenkins setup
- [IaC_PIPELINE_GUIDE.md](IaC_PIPELINE_GUIDE.md) - Infrastructure as Code pipeline
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration from GitHub Actions
- [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) - Verification checklist

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Commit changes: `git commit -am 'Add new feature'`
3. Push to branch: `git push origin feature/new-feature`
4. Submit pull request for review

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

**Built with ❤️ by the DevOps Team**  
**Jenkins CI/CD Edition**  
**SRE Project 2 - DevSecOps with AWS EKS and Jenkins ArgoCD**
