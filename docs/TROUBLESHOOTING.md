# Troubleshooting Guide

This guide provides detailed troubleshooting steps for common issues encountered in the DevOps CI/CD pipeline.

## Table of Contents

- [Stage 1: Platform Checks](#stage-1-platform-checks)
- [Stage 2: Validation](#stage-2-validation)
- [Stage 3: Build](#stage-3-build)
- [Stage 4: Package](#stage-4-package)
- [Stage 5: Container Scan](#stage-5-container-scan)
- [Stage 6: Promotion](#stage-6-promotion)
- [Infrastructure Issues](#infrastructure-issues)
- [ArgoCD Issues](#argocd-issues)
- [Kyverno Issues](#kyverno-issues)

---

## Stage 1: Platform Checks

### Issue: EKS Cluster Not Active

**Symptoms:**
```
❌ ERROR: EKS cluster is not ACTIVE. Current status: CREATING
```

**Diagnosis:**
```bash
aws eks describe-cluster --name cicd-pipeline-dev --region us-east-1 --query 'cluster.status'
```

**Solutions:**
1. Wait for cluster creation to complete (typically 10-15 minutes)
2. Check CloudFormation stacks for errors:
   ```bash
   aws cloudformation describe-stacks --region us-east-1
   ```
3. Review Terraform apply logs for errors

### Issue: Worker Nodes Not Ready

**Symptoms:**
```
❌ ERROR: Some worker nodes are not in Ready state
```

**Diagnosis:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**Common Causes & Solutions:**

1. **Insufficient IAM Permissions**
   ```bash
   # Verify node IAM role has required policies
   aws iam list-attached-role-policies --role-name cicd-pipeline-dev-node-group-role
   ```

2. **VPC CNI Issues**
   ```bash
   # Check VPC CNI pods
   kubectl get pods -n kube-system -l k8s-app=aws-node
   
   # Restart VPC CNI
   kubectl rollout restart daemonset aws-node -n kube-system
   ```

3. **Disk Pressure**
   ```bash
   # Check node conditions
   kubectl describe node <node-name> | grep -A 5 Conditions
   ```

### Issue: System Pods Not Running

**Symptoms:**
```
⚠️ WARNING: Some system pods are not running
```

**Diagnosis:**
```bash
kubectl get pods -n kube-system
kubectl describe pod <pod-name> -n kube-system
```

**Solutions:**
1. Check pod logs:
   ```bash
   kubectl logs <pod-name> -n kube-system
   ```

2. Verify CoreDNS configuration:
   ```bash
   kubectl get configmap coredns -n kube-system -o yaml
   ```

---

## Stage 2: Validation

### Issue: Dockerfile Linting Failures

**Common Hadolint Errors:**

#### DL3008: Pin versions in apt-get install
```dockerfile
# ❌ Bad
RUN apt-get install -y curl

# ✅ Good
RUN apt-get install -y curl=7.68.0-1ubuntu2.14
```

#### DL3009: Delete apt cache
```dockerfile
# ✅ Good
RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
```

#### DL3025: Use JSON array for CMD/ENTRYPOINT
```dockerfile
# ❌ Bad
CMD java -jar app.jar

# ✅ Good
CMD ["java", "-jar", "app.jar"]
```

### Issue: Kubernetes Manifest Validation Failed

**Symptoms:**
```
Error: Invalid value for field 'spec.containers[0].resources'
```

**Diagnosis:**
```bash
# Validate manually with kubeconform
kubeconform helm-chart/templates/deployment.yaml

# Or use kubectl dry-run
kubectl apply --dry-run=client -f helm-chart/templates/deployment.yaml
```

**Common Issues:**

1. **Missing Required Fields**
   ```yaml
   # Must specify resources
   resources:
     limits:
       cpu: 500m
       memory: 512Mi
     requests:
       cpu: 250m
       memory: 256Mi
   ```

2. **Invalid API Version**
   ```yaml
   # Check supported API versions
   kubectl api-versions
   ```

### Issue: Kyverno Policy Violations

**Symptoms:**
```
Policy restrict-privileged-containers failed: Privileged containers are not allowed
```

**Solutions:**

1. **Remove Privileged Flag**
   ```yaml
   securityContext:
     privileged: false  # or remove this line
   ```

2. **Add Resource Limits**
   ```yaml
   resources:
     limits:
       cpu: 500m
       memory: 512Mi
     requests:
       cpu: 250m
       memory: 256Mi
   ```

3. **Remove Host Namespace Access**
   ```yaml
   spec:
     hostPID: false
     hostIPC: false
     hostNetwork: false
   ```

### Issue: Snyk SAST Failures

**Symptoms:**
```
High severity vulnerabilities found in dependencies
```

**Solutions:**

1. **Update Dependencies**
   ```bash
   # Check for updates
   mvn versions:display-dependency-updates
   
   # Update specific dependency in pom.xml
   <dependency>
     <groupId>org.springframework.boot</groupId>
     <artifactId>spring-boot-starter-web</artifactId>
     <version>2.7.18</version>  <!-- Updated version -->
   </dependency>
   ```

2. **Adjust Severity Threshold** (temporary workaround)
   ```yaml
   # In .github/workflows/cicd-pipeline.yml
   env:
     SNYK_SEVERITY_THRESHOLD: "critical"  # Only block on critical
   ```

---

## Stage 3: Build

### Issue: Maven Build Failures

**Symptoms:**
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
```

**Common Causes:**

1. **Java Version Mismatch**
   ```xml
   <!-- Ensure pom.xml matches Docker image -->
   <properties>
     <java.version>11</java.version>
     <maven.compiler.source>11</maven.compiler.source>
     <maven.compiler.target>11</maven.compiler.target>
   </properties>
   ```

2. **Dependency Resolution Failures**
   ```bash
   # Clear Maven cache
   rm -rf ~/.m2/repository
   
   # Force update
   mvn clean install -U
   ```

3. **Test Failures**
   ```bash
   # Skip tests temporarily (not recommended for production)
   mvn clean package -DskipTests
   ```

---

## Stage 4: Package

### Issue: Docker Build Failures

**Symptoms:**
```
ERROR: failed to solve: failed to compute cache key
```

**Solutions:**

1. **Missing Build Context**
   ```bash
   # Ensure files exist
   ls -la target/*.jar
   ```

2. **Multi-stage Build Issues**
   ```dockerfile
   # Ensure COPY --from references correct stage
   COPY --from=builder /app/target/*.jar app.jar
   ```

3. **Base Image Pull Failures**
   ```bash
   # Test base image pull
   docker pull openjdk:11-jre-slim
   ```

### Issue: ECR Push Failures

**Symptoms:**
```
denied: Your authorization token has expired
```

**Solutions:**

1. **Re-authenticate**
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
   ```

2. **Check ECR Repository Exists**
   ```bash
   aws ecr describe-repositories --repository-names cicd-demo-app --region us-east-1
   ```

3. **Verify IAM Permissions**
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "ecr:GetAuthorizationToken",
       "ecr:BatchCheckLayerAvailability",
       "ecr:PutImage",
       "ecr:InitiateLayerUpload",
       "ecr:UploadLayerPart",
       "ecr:CompleteLayerUpload"
     ],
     "Resource": "*"
   }
   ```

### Issue: Helm Chart Packaging Failures

**Symptoms:**
```
Error: validation: chart.metadata.version is required
```

**Solutions:**

1. **Verify Chart.yaml**
   ```bash
   helm lint helm-chart/
   ```

2. **Check Template Syntax**
   ```bash
   helm template test-release helm-chart/ --debug
   ```

---

## Stage 5: Container Scan

### Issue: Snyk Container Scan Failures

**Symptoms:**
```
Error: Unable to pull image
```

**Solutions:**

1. **Authenticate to ECR**
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
   ```

2. **Pull Image Manually**
   ```bash
   docker pull ${IMAGE_TAG}
   docker images | grep cicd-demo-app
   ```

### Issue: High Severity Vulnerabilities

**Symptoms:**
```
✗ High severity vulnerability found in openssl
```

**Solutions:**

1. **Update Base Image**
   ```dockerfile
   # Use newer base image
   FROM openjdk:11-jre-slim-bullseye
   ```

2. **Apply Security Patches**
   ```dockerfile
   RUN apt-get update && apt-get upgrade -y \
       && rm -rf /var/lib/apt/lists/*
   ```

---

## Stage 6: Promotion

### Issue: Config Repository Update Failed

**Symptoms:**
```
fatal: could not read Username for 'https://github.com'
```

**Solutions:**

1. **Configure Git Token**
   ```bash
   # Set as GitHub Secret
   # Settings → Secrets and variables → Actions
   # Name: GH_TOKEN or use standard GITHUB_TOKEN
   ```

2. **Use SSH Key (Alternative)**
   ```bash
   # Add SSH key as GitHub Secret
   # Then reference in workflow
   ```

### Issue: ArgoCD Not Detecting Changes

**Symptoms:**
```
Application status: Synced (but old version)
```

**Solutions:**

1. **Force Refresh**
   ```bash
   argocd app get cicd-demo-app-dev --refresh
   ```

2. **Check Repository Connection**
   ```bash
   argocd repo list
   argocd repo get git@gitlab.com:your-org/config-repo.git
   ```

3. **Verify Webhook**
   ```bash
   # In GitHub: Settings → Webhooks
   # Add ArgoCD webhook URL
   ```

---

## Infrastructure Issues

### Issue: Terraform Apply Failures

**Symptoms:**
```
Error: Error creating EKS Cluster: InvalidParameterException
```

**Solutions:**

1. **Check AWS Quotas**
   ```bash
   aws service-quotas list-service-quotas --service-code eks
   ```

2. **Verify Subnet Configuration**
   ```bash
   # EKS requires at least 2 subnets in different AZs
   aws ec2 describe-subnets --subnet-ids subnet-xxx subnet-yyy
   ```

3. **Review Terraform State**
   ```bash
   terraform state list
   terraform state show module.eks.aws_eks_cluster.main
   ```

---

## ArgoCD Issues

### Issue: Application Health Degraded

**Symptoms:**
```
Health Status: Degraded
Sync Status: Synced
```

**Diagnosis:**
```bash
kubectl get application cicd-demo-app-dev -n argocd -o yaml
kubectl get pods -n dev
```

**Solutions:**

1. **Check Pod Status**
   ```bash
   kubectl describe pod <pod-name> -n dev
   kubectl logs <pod-name> -n dev
   ```

2. **Review Health Checks**
   ```yaml
   # Adjust probe timings in values.yaml
   livenessProbe:
     initialDelaySeconds: 60  # Increase if app takes longer to start
   ```

---

## Kyverno Issues

### Issue: Policies Not Enforcing

**Symptoms:**
```
Pods created despite policy violations
```

**Solutions:**

1. **Check Kyverno Installation**
   ```bash
   kubectl get pods -n kyverno
   kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
   ```

2. **Verify Policy Status**
   ```bash
   kubectl get clusterpolicy
   kubectl describe clusterpolicy restrict-privileged-containers
   ```

3. **Check Validation Mode**
   ```yaml
   # Ensure enforce mode
   spec:
     validationFailureAction: enforce  # not 'audit'
   ```

---

## Getting Help

If issues persist:

1. **Check Workflow Logs**
   - GitHub: Actions → Select Workflow → Select Run → Select Job

2. **Review Kubernetes Events**
   ```bash
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

3. **Contact Support**
   - Create an issue in the repository
   - Email: devops@example.com
