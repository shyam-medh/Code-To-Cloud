# Code-To-Cloud: Complete Step-by-Step Implementation Guide

This document provides an exhaustive, command-level walkthrough of every step performed to build this DevSecOps project from scratch.

---

## Table of Contents

1. [Phase 1: Infrastructure Provisioning](#phase-1-infrastructure-provisioning-terraform)
2. [Phase 2: Jenkins CI/CD Setup](#phase-2-jenkins-cicd-setup)
3. [Phase 3: Security Tool Integration](#phase-3-security-tool-integration)
4. [Phase 4: Application Containerization](#phase-4-application-containerization)
5. [Phase 5: Pipeline Automation](#phase-5-pipeline-automation)
6. [Phase 6: Continuous Deployment](#phase-6-continuous-deployment-zero-downtime)
7. [Challenges & Solutions](#challenges--solutions)

---

# Phase 1: Infrastructure Provisioning (Terraform)

## Step 1.1 — Create Terraform Project Structure

```bash
mkdir -p infrastructure/modules/{vpc,tgw,security,nlb,asg,rds,jenkins}
```

Each module is self-contained with its own `main.tf`, `variables.tf`, and `outputs.tf`.

## Step 1.2 — Configure the AWS Provider

```hcl
# providers.tf
provider "aws" {
  region = var.aws_region   # ap-south-1
}
```

## Step 1.3 — Provision the Dual-VPC Network

Two VPCs were created — one for DevOps tooling, one for the live application:

```hcl
# Management VPC
resource "aws_vpc" "mgmt" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Production VPC
resource "aws_vpc" "prod" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```

### Subnets Created:
| VPC | Subnet | CIDR | Type | AZ |
|---|---|---|---|---|
| Management | mgmt-public-1a | `10.0.1.0/24` | Public | ap-south-1a |
| Production | prod-public-1a | `10.1.1.0/24` | Public | ap-south-1a |
| Production | prod-public-1b | `10.1.2.0/24` | Public | ap-south-1b |
| Production | prod-app-1a | `10.1.3.0/24` | Private | ap-south-1a |
| Production | prod-app-1b | `10.1.4.0/24` | Private | ap-south-1b |
| Production | prod-db-1a | `10.1.5.0/24` | Private | ap-south-1a |
| Production | prod-db-1b | `10.1.6.0/24` | Private | ap-south-1b |

### Gateway & Routing:
- **Internet Gateway** attached to both VPCs for public subnet internet access
- **NAT Gateways** (one per AZ) for private subnet outbound internet access
- **Route Tables** configured to direct traffic to IGW (public) or NAT (private)

## Step 1.4 — Deploy AWS Transit Gateway

```hcl
resource "aws_ec2_transit_gateway" "main" {
  description = "Connects Management and Production VPCs"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "mgmt" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.mgmt.id
  subnet_ids         = [aws_subnet.mgmt_public_1a.id]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.prod.id
  subnet_ids         = [aws_subnet.prod_app_1a.id, aws_subnet.prod_app_1b.id]
}
```

Route table entries were added so traffic destined for `10.1.0.0/16` from the Management VPC is routed through the TGW, and vice versa.

## Step 1.5 — Create Security Groups

Seven security groups were created following the **principle of least privilege**:

```hcl
# Example: App servers only accept traffic from the Internal NLB
resource "aws_security_group" "app" {
  name   = "prod-app-sg"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_nlb.id]
  }
}
```

## Step 1.6 — Provision Network Load Balancers

```hcl
# Public NLB (Internet → Nginx)
resource "aws_lb" "public" {
  name               = "prod-public-nlb"
  internal           = false
  load_balancer_type = "network"
}

# Internal NLB (Nginx → Java App)
resource "aws_lb" "internal" {
  name               = "prod-internal-nlb"
  internal           = true
  load_balancer_type = "network"
}
```

Target Groups with TCP health checks on ports 80 and 8081 respectively.

## Step 1.7 — Create Auto Scaling Groups

```hcl
resource "aws_autoscaling_group" "nginx" {
  name                = "prod-nginx-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  target_group_arns   = [aws_lb_target_group.nginx.arn]
  vpc_zone_identifier = var.private_app_subnets
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
}
```

The Nginx Launch Template includes a `user_data` script that:
1. Installs Docker
2. Dynamically writes an `nginx.conf` with the Internal NLB DNS
3. Starts an Nginx container with the config mounted

## Step 1.8 — Provision RDS MySQL

```hcl
resource "aws_db_instance" "mysql_master" {
  identifier           = "prod-mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "tasktracker"
  skip_final_snapshot  = true
}
```

## Step 1.9 — Deploy Jenkins Instances

```hcl
resource "aws_instance" "jenkins_master" {
  ami                    = "ami-0e35ddab05955cf57"
  instance_type          = "t2.medium"
  subnet_id              = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_master_sg_id]
}

resource "aws_instance" "jenkins_slave" {
  ami                    = "ami-0e35ddab05955cf57"
  instance_type          = "t2.medium"
  subnet_id              = var.mgmt_subnets[0]
  vpc_security_group_ids = [var.jenkins_slave_sg_id]
}
```

## Step 1.10 — Apply the Infrastructure

```bash
cd infrastructure
terraform init
terraform plan        # Review all 40+ resources
terraform apply -auto-approve
```

---

# Phase 2: Jenkins CI/CD Setup

## Step 2.1 — Access Jenkins Master

```
http://<jenkins-master-public-ip>:8080
```

Retrieve the initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Install suggested plugins and create an admin user.

## Step 2.2 — Configure Jenkins Slave Node

1. Navigate to **Manage Jenkins** → **Nodes** → **New Node**
2. Configure:
   ```
   Name:            slave
   Remote Root Dir: /home/ubuntu/jenkins
   Labels:          slave
   Launch Method:   Launch via SSH
   Host:            <slave-private-ip>
   Credentials:     SSH private key (slave_key)
   ```

## Step 2.3 — Install Tools on Jenkins Slave

```bash
# Java 17 (required by Jenkins agent)
sudo apt install -y openjdk-17-jdk

# Maven
sudo apt install -y maven

# Docker
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# AWS CLI
sudo apt install -y awscli

# SonarQube (Docker container)
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# Trivy is run as a Docker container during the pipeline
# Checkov is run as a Docker container during the pipeline
```

## Step 2.4 — Add Jenkins Credentials

| Credential ID | Type | Purpose |
|---|---|---|
| `docker-hub-credentials` | Username/Password | Docker Hub login (Access Token as password) |
| `sonarqube-token` | Secret Text | SonarQube authentication token |

Navigate to: **Manage Jenkins** → **Credentials** → **System** → **Global credentials** → **Add Credentials**

## Step 2.5 — Create Jenkins Pipeline Job

1. Click **New Item** → Enter name → Select **Pipeline**
2. Under **Build Triggers**: Check **GitHub hook trigger for GITScm polling**
3. Under **Pipeline**: Select **Pipeline script from SCM**
   ```
   SCM:              Git
   Repository URL:   https://github.com/shyam-medh/Code-To-Cloud.git
   Branch:           */main
   Script Path:      Jenkinsfile
   ```

---

# Phase 3: Security Tool Integration

## Step 3.1 — Checkov (Infrastructure as Code Security)

Runs inside the Jenkins pipeline using the official Docker container:
```groovy
stage('Checkov Security Scan') {
    steps {
        sh "docker run --rm -v \$(pwd):/tf bridgecrew/checkov -d /tf/infrastructure || true"
    }
}
```
**What it scans**: Open security groups, unencrypted storage, missing logging, overly permissive IAM policies.

## Step 3.2 — SonarQube (Static Application Security Testing)

```groovy
stage('SonarQube Analysis') {
    steps {
        dir('task-tracker') {
            withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                sh "mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=task-tracker \
                    -Dsonar.host.url=http://localhost:9000 \
                    -Dsonar.login=${SONAR_TOKEN}"
            }
        }
    }
}
```
**What it scans**: Java code bugs, code smells, security vulnerabilities, test coverage.

Access the SonarQube dashboard at: `http://<jenkins-slave-ip>:9000`

## Step 3.3 — Trivy (Container Vulnerability Scanning)

```groovy
stage('Trivy Vulnerability Scan') {
    steps {
        sh "docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image \
            --severity HIGH,CRITICAL \
            shyammedh/java-app:${env.BUILD_NUMBER} || true"
    }
}
```
**What it scans**: OS package CVEs, application library vulnerabilities inside the Docker image.

---

# Phase 4: Application Containerization

## Step 4.1 — Write the Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build (heavy image with Maven + JDK)
FROM maven:3.9.5-eclipse-temurin-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B     # Cache dependencies
COPY src ./src
RUN mvn clean package -DskipTests    # Compile the JAR

# Stage 2: Runtime (lightweight image with JRE only)
FROM eclipse-temurin:11-jre
WORKDIR /app
COPY --from=builder /app/target/tasktracker-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Step 4.2 — Build and Tag

```groovy
stage('Build Docker Image') {
    steps {
        dir('task-tracker') {
            sh "docker build -t shyammedh/java-app:latest \
                             -t shyammedh/java-app:${env.BUILD_NUMBER} ."
        }
    }
}
```

## Step 4.3 — Push to Docker Hub

```groovy
stage('Push to Docker Hub') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'docker-hub-credentials',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS')]) {
            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
            sh "docker push shyammedh/java-app:latest"
            sh "docker push shyammedh/java-app:${env.BUILD_NUMBER}"
        }
    }
}
```

---

# Phase 5: Pipeline Automation

## Step 5.1 — Configure GitHub Webhook

1. Go to GitHub repository → **Settings** → **Webhooks** → **Add webhook**
2. Set:
   ```
   Payload URL:    http://<jenkins-master-ip>:8080/github-webhook/
   Content type:   application/json
   Which events:   Just the push event
   Active:         ✅
   ```
3. Click **Add webhook** — GitHub will send a test ping

Now every `git push` to `main` automatically triggers the full Jenkins pipeline.

## Step 5.2 — Full Pipeline Flow

```
Developer → git push → GitHub → Webhook → Jenkins Master → Jenkins Slave
    ├── Checkov scan (Terraform)
    ├── SonarQube scan (Java code)
    ├── Docker build (multi-stage)
    ├── Trivy scan (Docker image)
    ├── Docker push (Docker Hub)
    └── AWS ASG Instance Refresh (zero-downtime deploy)
```

---

# Phase 6: Continuous Deployment (Zero-Downtime)

## Step 6.1 — Trigger ASG Instance Refresh

```groovy
stage('Deploy to AWS (Continuous Deployment)') {
    steps {
        sh "aws autoscaling start-instance-refresh \
            --auto-scaling-group-name devops-app-asg \
            --region ap-south-1"
    }
}
```

## Step 6.2 — What Happens Behind the Scenes

1. AWS starts replacing instances in the ASG one-by-one
2. A **new EC2 instance** launches with the latest Launch Template
3. The `user_data` script runs: installs Docker → pulls `shyammedh/java-app:latest` → starts the container
4. The NLB **health check** confirms the new instance is healthy (TCP port 8081 responds)
5. AWS **drains connections** from the old instance (waits for in-flight requests to finish)
6. The old instance is **terminated**
7. Process repeats until all instances are refreshed

**Result**: Users experience zero downtime — traffic is seamlessly shifted to the new version.

---

# Challenges & Solutions

### 1. Asymmetric Routing (504 Gateway Timeout)
**Problem**: The Internal NLB preserved client IPs. Since Nginx and the Java App were in the same subnet, the Java App replied directly to Nginx, bypassing the NLB. Nginx dropped the response because it expected a reply from the NLB.

**Solution**: Set `preserve_client_ip = "false"` on the Internal NLB Target Group.

### 2. AWS vCPU Quota Limit
**Problem**: ASG Instance Refresh tried to launch new instances before terminating old ones, exceeding the 16 vCPU free-tier limit.

**Solution**: Terminated stale instances manually and let the ASG retry.

### 3. Nginx Variable Interpolation
**Problem**: Terraform's `templatefile()` function was interpolating Nginx's `$host` and `$remote_addr` variables as empty strings.

**Solution**: Used heredoc with `'EOCONF'` (single-quoted delimiter) to prevent Terraform variable substitution while allowing only `${internal_nlb_dns}` to be injected.

### 4. SonarQube Java Version Mismatch
**Problem**: SonarQube required Java 17 but the Jenkins Slave had Java 11.

**Solution**: Installed OpenJDK 17 alongside Java 11 and configured the Jenkins agent to use Java 17.

### 5. Docker Hub Authentication Loop
**Problem**: Jenkins failed with `Could not find credentials entry with ID 'docker-hub-credentials'`.

**Solution**: Created the credential in Jenkins using a **Docker Hub Access Token** (not the account password) under the exact ID `docker-hub-credentials`.

---

> **Tip**: When you are completely finished with this project, destroy all AWS resources to avoid charges:
> ```bash
> cd infrastructure
> terraform destroy -auto-approve
> ```
