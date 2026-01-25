# DevOps CI/CD Pipeline Implementation Plan

This implementation creates a production-ready CI/CD pipeline for deploying applications to AWS EKS with comprehensive security scanning, policy enforcement, and GitOps-based deployment using ArgoCD.

## User Review Required

> [!IMPORTANT]
> **Technology Stack Confirmation**
> - **CI/CD Platform**: GitHub Actions
> - **Container Registry**: AWS ECR
> - **Kubernetes**: AWS EKS
> - **GitOps Tool**: ArgoCD
> - **Security Scanning**: Snyk (requires API token)
> - **Policy Engine**: Kyverno
> - **Build Tool**: Maven (for Java applications)
> - **Package Manager**: Helm 3

> [!WARNING]
> **Required Credentials & Tokens**
> - AWS credentials with EKS, ECR, VPC permissions
> - Snyk API token for security scanning
> - GitHub repository with Actions enabled
> - ArgoCD repository access

## Proposed Changes

### Infrastructure as Code (Terraform)

#### [NEW] [terraform/](file:///d:/learning/sre-project-1/terraform/)
Complete Terraform infrastructure for AWS EKS cluster, networking, and supporting services.

##### [NEW] [main.tf](file:///d:/learning/sre-project-1/terraform/main.tf)
Root Terraform configuration with provider setup and module orchestration.

##### [NEW] [variables.tf](file:///d:/learning/sre-project-1/terraform/variables.tf)
Input variables for environment configuration (dev, qa, prod).

##### [NEW] [outputs.tf](file:///d:/learning/sre-project-1/terraform/outputs.tf)
Output values for EKS cluster endpoint, ECR repository URLs, and cluster details.

##### [NEW] [backend.tf](file:///d:/learning/sre-project-1/terraform/backend.tf)
S3 backend configuration for Terraform state management.

---

#### [NEW] [terraform/modules/eks/](file:///d:/learning/sre-project-1/terraform/modules/eks/)
EKS cluster module with managed node groups, IRSA, and cluster add-ons.

##### [NEW] [main.tf](file:///d:/learning/sre-project-1/terraform/modules/eks/main.tf)
EKS cluster, node groups, and IAM roles for service accounts.

##### [NEW] [variables.tf](file:///d:/learning/sre-project-1/terraform/modules/eks/variables.tf)
EKS-specific variables (cluster name, version, node instance types).

##### [NEW] [outputs.tf](file:///d:/learning/sre-project-1/terraform/modules/eks/outputs.tf)
Cluster endpoint, certificate authority, and OIDC provider outputs.

---

#### [NEW] [terraform/modules/vpc/](file:///d:/learning/sre-project-1/terraform/modules/vpc/)
VPC module with public/private subnets, NAT gateways, and EKS-specific tags.

##### [NEW] [main.tf](file:///d:/learning/sre-project-1/terraform/modules/vpc/main.tf)
VPC, subnets, route tables, internet gateway, and NAT gateway configuration.

---

#### [NEW] [terraform/modules/ecr/](file:///d:/learning/sre-project-1/terraform/modules/ecr/)
ECR repositories with lifecycle policies and image scanning.

##### [NEW] [main.tf](file:///d:/learning/sre-project-1/terraform/modules/ecr/main.tf)
ECR repository creation with scan-on-push and lifecycle policies.

---

### CI/CD Pipeline Configuration

#### [NEW] [.github/workflows/cicd-pipeline.yml](file:///d:/learning/sre-project-1/.github/workflows/cicd-pipeline.yml)
Complete GitHub Actions workflow implementing multiple jobs with security scanning, policy validation, and ArgoCD integration.

**Pipeline Jobs:**
1. **platform-check**: Validates EKS cluster health and node readiness
2. **validate-dockerfile**: Dockerfile linting with Hadolint
3. **validate-kubernetes**: Kubernetes syntax validation with kubeconform
4. **validate-kyverno-policies**: Kyverno policy checks
5. **sast-snyk**: Snyk SAST security scanning
6. **build-maven**: Maven build to create JAR/WAR artifacts
7. **package-docker**: Docker image build, tagging, ECR push
8. **package-helm**: Helm chart packaging, ECR push
9. **scan-container**: Snyk container image vulnerability scanning
10. **promote**: Update config repo for ArgoCD, trigger deployment
11. **approval-gate-qa**: Manual approval for QA deployment
12. **approval-gate-prod**: Manual approval for production deployment

---

### Application Components

#### [NEW] [Dockerfile](file:///d:/learning/sre-project-1/Dockerfile)
Multi-stage Dockerfile for Java application with security best practices.

---

#### [NEW] [helm-chart/](file:///d:/learning/sre-project-1/helm-chart/)
Helm chart for Kubernetes deployment with configurable values.

##### [NEW] [Chart.yaml](file:///d:/learning/sre-project-1/helm-chart/Chart.yaml)
Helm chart metadata and version information.

##### [NEW] [values.yaml](file:///d:/learning/sre-project-1/helm-chart/values.yaml)
Default configuration values for deployment, service, ingress, resources.

##### [NEW] [templates/deployment.yaml](file:///d:/learning/sre-project-1/helm-chart/templates/deployment.yaml)
Kubernetes Deployment manifest with resource limits and health checks.

##### [NEW] [templates/service.yaml](file:///d:/learning/sre-project-1/helm-chart/templates/service.yaml)
Kubernetes Service manifest.

##### [NEW] [templates/ingress.yaml](file:///d:/learning/sre-project-1/helm-chart/templates/ingress.yaml)
Kubernetes Ingress manifest for external access.

##### [NEW] [templates/configmap.yaml](file:///d:/learning/sre-project-1/helm-chart/templates/configmap.yaml)
ConfigMap for application configuration.

---

#### [NEW] [kyverno-policies/](file:///d:/learning/sre-project-1/kyverno-policies/)
Kyverno policy definitions for security and compliance.

##### [NEW] [restrict-privileged-pods.yaml](file:///d:/learning/sre-project-1/kyverno-policies/restrict-privileged-pods.yaml)
Policy to prevent creation of privileged containers.

##### [NEW] [require-resource-limits.yaml](file:///d:/learning/sre-project-1/kyverno-policies/require-resource-limits.yaml)
Policy to enforce CPU and memory limits on all pods.

---

#### [NEW] [argocd/](file:///d:/learning/sre-project-1/argocd/)
ArgoCD application definitions for GitOps deployment.

##### [NEW] [application-dev.yaml](file:///d:/learning/sre-project-1/argocd/application-dev.yaml)
ArgoCD Application manifest for dev environment.

##### [NEW] [application-qa.yaml](file:///d:/learning/sre-project-1/argocd/application-qa.yaml)
ArgoCD Application manifest for qa environment.

##### [NEW] [application-prod.yaml](file:///d:/learning/sre-project-1/argocd/application-prod.yaml)
ArgoCD Application manifest for prod environment.

---

### Scripts and Utilities

#### [NEW] [scripts/](file:///d:/learning/sre-project-1/scripts/)
Helper scripts for pipeline stages and cluster validation.

##### [NEW] [check-eks-cluster.sh](file:///d:/learning/sre-project-1/scripts/check-eks-cluster.sh)
Script to validate EKS cluster health and node readiness (Stage 1).

##### [NEW] [validate-k8s-manifests.sh](file:///d:/learning/sre-project-1/scripts/validate-k8s-manifests.sh)
Script to validate Kubernetes YAML syntax using kubeval/kubeconform (Stage 2).

##### [NEW] [update-config-repo.sh](file:///d:/learning/sre-project-1/scripts/update-config-repo.sh)
Script to update config.yaml in GitOps repository (Stage 6).

---

### Sample Application

#### [NEW] [src/main/java/com/example/App.java](file:///d:/learning/sre-project-1/src/main/java/com/example/App.java)
Sample Java application for demonstration.

#### [NEW] [pom.xml](file:///d:/learning/sre-project-1/pom.xml)
Maven POM file for building the Java application.

---

### Documentation

#### [NEW] [README.md](file:///d:/learning/sre-project-1/README.md)
Comprehensive documentation covering:
- Pipeline stages overview
- Infrastructure setup instructions
- CI/CD configuration
- Deployment workflow
- Troubleshooting guide
- Prerequisites and requirements

#### [NEW] [docs/TROUBLESHOOTING.md](file:///d:/learning/sre-project-1/docs/TROUBLESHOOTING.md)
Detailed troubleshooting guide for common issues in each pipeline stage.

## Verification Plan

### Automated Tests
1. **Terraform Validation**: Run `terraform validate` and `terraform plan` for all modules
2. **Workflow Syntax**: Validate `.github/workflows/cicd-pipeline.yml` syntax
3. **Helm Chart Validation**: Run `helm lint helm-chart/` to validate chart structure
4. **Kubernetes Manifest Validation**: Use `kubeval` or `kubeconform` on generated manifests

### Manual Verification
1. **Infrastructure Deployment**: Deploy Terraform infrastructure to a test AWS account
2. **Workflow Execution**: Push to dev/qa/prod branch and verify all jobs complete successfully
3. **ArgoCD Integration**: Verify ArgoCD detects and deploys the application
4. **Security Scanning**: Confirm Snyk reports are generated for both SAST and container scanning
5. **Policy Enforcement**: Test Kyverno policies by attempting to create non-compliant resources
