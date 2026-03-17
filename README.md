# 🚀 RoboShop Infrastructure — AWS DevOps

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)

Production-grade e-commerce infrastructure using **Terraform** and **AWS**. Implements microservices architecture with automated deployments, high availability, and security best practices.

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Infrastructure Layers](#-infrastructure-layers)
- [Key Features](#-key-features)
- [Deployment Guide](#-deployment-guide)
- [Technologies](#-technologies)

---

## 🏗️ Architecture Overview
```
Internet
    │
    ▼
Frontend ALB (Public) → Frontend Service
    │
    ▼
Backend ALB (Internal)
    │
    ├── Catalogue → MongoDB
    ├── User      → MongoDB, Redis
    ├── Cart      → Redis
    ├── Shipping  → MySQL
    └── Payment   → RabbitMQ
```

**Design Principles:**
- Multi-tier architecture (Frontend → Backend → Database)
- Service isolation via security groups
- High availability across 2 AZs
- Immutable infrastructure (Golden AMI pattern)
- Zero-downtime deployments (Auto Scaling rolling updates)

---

## 🧱 Infrastructure Layers

### 00-vpc
**Foundation networking**
- VPC with 3 subnet tiers (Public, Private, Database)
- Internet Gateway + NAT Gateway
- Multi-AZ deployment (us-east-1a, us-east-1b)

### 10-sg
**Security groups** for all components
- Separate SGs per service (13 total)
- Principle of least privilege
- IDs stored in SSM Parameter Store

### 20-sg-rules
**Network communication rules**
- Service-to-service communication
- Database access control
- Bastion SSH access
- ALB traffic routing

### 30-bastion
**Secure access point**
- Jump server in public subnet
- Restricted SSH access via security group
- IAM role for AWS CLI operations

### 40-databases
**Data layer**
- MongoDB (DocumentDB)
- Redis (ElastiCache)
- MySQL (RDS-ready, currently EC2)
- RabbitMQ (Message broker)
- Automated Ansible configuration
- Route53 DNS service discovery

### 50-backend-alb
**Internal load balancer**
- Application Load Balancer (Layer 7)
- Host-based routing (`service.backend-alb-dev.domain`)
- Health checks on `/health` endpoint
- Wildcard DNS (`*.backend-alb-dev.domain`)

### 60-catalogue
**First microservice deployment**
- Golden AMI creation via Terraform provisioners
- Launch Template with versioning
- Auto Scaling Group (min: 1, max: 10)
- Target Group with health checks
- ALB Listener Rule (priority-based routing)

### 70-acm
**SSL/TLS certificates**
- AWS Certificate Manager integration
- Wildcard certificate (`*.domain.com`)
- Automatic validation via Route53
- HTTPS termination at ALB

### 80-frontend-alb
**Public-facing load balancer**
- Internet-facing ALB
- HTTPS listener (port 443)
- SSL certificate attachment
- Routes to Frontend target group

### 90-components
**Centralized microservice deployment**
- Single module with `for_each` loop
- Deploys all services from one folder
- Shared bootstrap.sh with Ansible
- Phased rollout strategy (commented services)

---

## ✨ Key Features

### Infrastructure as Code
- **Modular design**: Reusable VPC and SG modules
- **Layer isolation**: Independent Terraform states
- **SSM integration**: Cross-layer data sharing

### Security
- **IAM roles**: No hardcoded credentials
- **SSM SecureString**: Encrypted secrets (KMS)
- **Security groups**: Reference-based rules (no IPs)
- **Bastion pattern**: Secure private subnet access

### High Availability
- **Multi-AZ**: Resources across 2 availability zones
- **Auto Scaling**: CPU-based scaling (target: 70%)
- **Health checks**: ALB monitors `/health` endpoint
- **Rolling updates**: Zero-downtime deployments (50% min healthy)

### Automation
- **Golden AMI**: Pre-baked application images
- **Ansible integration**: Configuration management
- **Bootstrap scripts**: Automated instance setup
- **DNS automation**: Route53 service discovery

---

## 🚀 Deployment Guide

**Prerequisites:**
- AWS Account with appropriate permissions
- Terraform >= 1.0
- Configured AWS CLI (`aws configure`)

**Deployment Order:**
```bash
# 1. Network foundation
cd 00-vpc && terraform init && terraform apply

# 2. Security groups
cd ../10-sg && terraform init && terraform apply

# 3. Security rules
cd ../20-sg-rules && terraform init && terraform apply

# 4. Bastion host
cd ../30-bastion && terraform init && terraform apply

# 5. Databases
cd ../40-databases && terraform init && terraform apply

# 6. Backend ALB
cd ../50-backend-alb && terraform init && terraform apply

# 7. SSL certificates
cd ../70-acm && terraform init && terraform apply

# 8. Frontend ALB
cd ../80-frontend-alb && terraform init && terraform apply

# 9. All microservices (optimized approach)
cd ../90-components && terraform init && terraform apply
```

**Alternative (Individual Services):**
```bash
cd 60-catalogue && terraform apply
cd 70-user && terraform apply
# ... repeat for each service
```

---

## 📦 Repository Structure
```
roboshop-infra-dev/
├── infra/
│   ├── 00-vpc/
│   ├── 10-sg/
│   ├── 20-sg-rules/
│   ├── 30-bastion/
│   ├── 40-databases/
│   ├── 50-backend-alb/
│   ├── 60-catalogue/
│   ├── 70-acm/
│   ├── 80-frontend-alb/
│   └── 90-components/        ← Centralized deployment
│
└── modules/
    ├── terraform-aws-vpc/
    ├── terraform-aws-sg/
    └── terraform-roboshop-component/
```

---

## 🔐 SSM Parameter Store Pattern

**Decoupled infrastructure layers:**
```
Layer A (00-vpc)          Layer B (50-backend-alb)
     │                             │
     ├─ Create VPC                 ├─ Read VPC ID
     ├─ Create Subnets             ├─ Read Subnet IDs
     │                             │
     └─ Store in SSM ────SSM───────┘ Retrieve from SSM
```

**Example parameters:**
```
/roboshop/dev/vpc_id
/roboshop/dev/private_subnet_ids
/roboshop/dev/catalogue_sg_id
/roboshop/dev/backend_alb_listener_arn
```

**Benefits:**
- Independent deployments
- No Terraform state dependencies
- Team collaboration
- CI/CD pipeline friendly

---

## 🛠️ Technologies

| Technology | Purpose |
|------------|---------|
| **Terraform** | Infrastructure provisioning |
| **AWS VPC** | Network isolation |
| **Application Load Balancer** | Traffic distribution |
| **Auto Scaling** | Dynamic capacity management |
| **Route53** | DNS & service discovery |
| **SSM Parameter Store** | Configuration & secrets |
| **IAM** | Access control |
| **Ansible** | Configuration management |
| **ACM** | SSL/TLS certificates |

---

## 🎯 DevOps Patterns Implemented

- ✅ **Infrastructure as Code** (Terraform)
- ✅ **Immutable Infrastructure** (Golden AMI)
- ✅ **Zero-Downtime Deployments** (Rolling updates)
- ✅ **Service Discovery** (Route53 DNS)
- ✅ **Security Groups Over IPs** (Reference-based rules)
- ✅ **Secrets Management** (SSM + IAM)
- ✅ **Multi-Tier Architecture** (3-tier separation)
- ✅ **High Availability** (Multi-AZ deployment)
- ✅ **Auto Scaling** (CPU-based policies)
- ✅ **Health Checks** (ALB monitoring)
- ✅ **Modular Design** (Reusable modules)
- ✅ **Configuration Management** (Ansible)

---

## 🔮 Roadmap

- [x] VPC & Networking
- [x] Security Groups
- [x] Bastion Host
- [x] Database Layer
- [x] Backend ALB
- [x] SSL Certificates
- [x] Frontend ALB
- [x] Microservices Deployment
- [ ] CloudWatch Monitoring
- [ ] CI/CD Pipeline (GitHub Actions)
- [ ] EKS Migration
- [ ] Cost Optimization
- [ ] WAF Integration

---

## 👨‍💻 Author

**Ramu Chelloju**  
DevOps Engineer | AWS | Terraform | Kubernetes

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ramuchelloju/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/chellojuramu)

---

⭐ **Star this repo** if you find it helpful!
