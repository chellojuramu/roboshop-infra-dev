# 🚀 Roboshop Infrastructure — DevOps on AWS

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)

Infrastructure as Code (IaC) repository for provisioning the **Roboshop application infrastructure** using **Terraform and AWS**.

This repository follows a **modular and layered infrastructure design**, allowing components to be created, managed, and extended independently.

The goal of this project is to build a **production-style DevOps infrastructure architecture** that can evolve over time with additional services such as compute layers, load balancers, Kubernetes clusters, CI/CD pipelines, monitoring, and more.

---

## 📑 Table of Contents

- [Project Architecture](#-project-architecture)
- [Complete System Architecture](#-complete-system-architecture)
- [Infrastructure Layers](#-infrastructure-layers)
  - [00-vpc](#00-vpc)
  - [10-sg](#10-sg)
  - [20-sg-rules](#20-sg-rules)
  - [30-bastion](#30-bastion)
  - [40-databases](#40-databases)
  - [50-backend-alb](#50-backend-alb)
- [Terraform Modules](#-terraform-modules)
- [SSM Parameter Store Integration](#-ssm-parameter-store-integration)
- [Secure Secret Management](#-secure-secret-management-ssm--iam)
- [Wildcard DNS Routing](#-wildcard-dns-routing)
- [Deployment Workflow](#-deployment-workflow)
- [Key DevOps Concepts Implemented](#-key-devops-concepts-implemented)
- [FAANG Interview Reference](#-faang-interview-reference)
- [Future Enhancements](#-future-enhancements)
- [Technologies Used](#-technologies-used)
- [Author](#-author)

---

## 📁 Project Architecture

This repository is organized into **two main sections**:

```
roboshop-infra-dev
│
├── infra
│   ├── 00-vpc
│   ├── 10-sg
│   ├── 20-sg-rules
│   ├── 30-bastion
│   ├── 40-databases
│   └── 50-backend-alb
│
├── modules
│   ├── terraform-aws-vpc
│   └── terraform-aws-sg
```

---

## 🏗️ Complete System Architecture

```
                        ┌──────────────────────────────────────────────────────┐
                        │                   INTERNET                           │
                        └──────────────────────┬───────────────────────────────┘
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────────────┐
                        │            Frontend ALB (Internet-Facing)            │
                        │               Public Subnets                        │
                        └──────────────────────┬───────────────────────────────┘
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────────────┐
                        │            Backend ALB (Internal)                    │
                        │               Private Subnets                       │
                        │                                                      │
                        │   Listener (HTTP :80)                                │
                        │       │                                              │
                        │       ├── catalogue.backend-alb → Catalogue TG       │
                        │       ├── user.backend-alb      → User TG            │
                        │       ├── cart.backend-alb      → Cart TG            │
                        │       ├── shipping.backend-alb  → Shipping TG        │
                        │       └── payment.backend-alb   → Payment TG         │
                        └──────────────────────┬───────────────────────────────┘
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────────────┐
                        │              Microservices Layer                      │
                        │   (catalogue, user, cart, shipping, payment)          │
                        │               Private Subnets                        │
                        └──────────────────────┬───────────────────────────────┘
                                               │
                                               ▼
                        ┌──────────────────────────────────────────────────────┐
                        │              Database Layer                          │
                        │   (MongoDB, Redis, MySQL, RabbitMQ)                  │
                        │               Database Subnets (Isolated)            │
                        └──────────────────────────────────────────────────────┘
```

**Key Design Decisions:**

| Traffic Type | Load Balancer | Subnet Type | Purpose |
|---|---|---|---|
| Public (User) | Frontend ALB | Public | Serves user-facing traffic |
| Internal (Service-to-Service) | Backend ALB | Private | Routes between microservices |
| Database | None (Direct SG) | Database (Isolated) | No internet access |
| Admin | Bastion Host | Public | Secure SSH into private resources |

---

## 🧱 Infrastructure Layers

The infrastructure is created in **logical layers**, where each layer depends on the previous one.

---

### 00-vpc

Creates the foundational networking components:

- VPC
- Public Subnets (2 AZs)
- Private Subnets (2 AZs)
- Database Subnets (2 AZs)
- Internet Gateway
- NAT Gateway
- Route Tables

Key outputs such as **VPC ID and Subnet IDs** are stored in **AWS Systems Manager Parameter Store** for use by other modules.

**Network Layout:**

```
VPC (10.0.0.0/16)
│
├── Public Subnets     → Internet Gateway → Internet
│   ├── AZ-1a
│   └── AZ-1b
│
├── Private Subnets    → NAT Gateway → Internet (outbound only)
│   ├── AZ-1a
│   └── AZ-1b
│
└── Database Subnets   → No internet access (isolated)
    ├── AZ-1a
    └── AZ-1b
```

---

### 10-sg

Creates **security groups** for all application components.

| Security Group | Purpose |
|---|---|
| `mongodb` | MongoDB database access |
| `redis` | Redis cache access |
| `mysql` | MySQL database access |
| `rabbitmq` | RabbitMQ message broker access |
| `catalogue` | Catalogue microservice |
| `user` | User microservice |
| `cart` | Cart microservice |
| `shipping` | Shipping microservice |
| `payment` | Payment microservice |
| `backend_alb` | Backend Application Load Balancer |
| `frontend` | Frontend application |
| `frontend_alb` | Frontend Application Load Balancer |
| `bastion` | Bastion host SSH access |

Security group IDs are stored in **SSM Parameter Store** to enable cross-module usage.

---

### 20-sg-rules

Defines the **network communication rules** between services.

**Example Rules:**

```
Bastion ──(SSH:22)──────→ MongoDB
Bastion ──(SSH:22)──────→ Redis
Catalogue ──(27017)─────→ MongoDB
User ──(27017)──────────→ MongoDB
Cart ──(6379)───────────→ Redis
Shipping ──(3306)───────→ MySQL
Payment ──(5672)────────→ RabbitMQ
Backend ALB ──(8080)────→ Catalogue
Backend ALB ──(8080)────→ User
Backend ALB ──(8080)────→ Cart
Backend ALB ──(8080)────→ Shipping
Backend ALB ──(8080)────→ Payment
```

> 💡 **Best Practice:** Security group rules reference **SG IDs instead of IP addresses**. This ensures rules remain valid even when instance IPs change (auto scaling, replacements).

---

### 30-bastion

Creates a **Bastion Host EC2 instance** used to securely access private infrastructure resources.

**Features:**

- EC2 instance in public subnet
- IAM role attached via instance profile
- Security group restricting SSH access to a specific IP
- Custom root volume configuration
- Bootstrap script using provisioners
- Secure entry point into private subnets
- Infrastructure management from inside the VPC

**Access Pattern:**

```
Developer ──(SSH)──→ Bastion Host (Public Subnet)
                         │
                         ├──(SSH)──→ Database Instances (DB Subnet)
                         ├──(SSH)──→ Application Instances (Private Subnet)
                         └──(HTTP)─→ Internal Services (Private Subnet)
```

---

### 40-databases

Creates the database infrastructure.

**Resources:**

| Database | Type | Port | Subnet |
|---|---|---|---|
| MongoDB | Document DB | 27017 | Database |
| Redis | Cache/In-Memory | 6379 | Database |
| MySQL | Relational DB | 3306 | Database |
| RabbitMQ | Message Broker | 5672 | Database |

**Features:**

- Instances launched in database subnets (isolated)
- Security groups applied dynamically using `for_each`
- Route53 DNS records automatically created
- Instance configuration handled using Terraform `terraform_data`
- Ansible used for service configuration
- IAM Role attached to MySQL instance for secure secret retrieval

**Configuration Flow:**

```
Terraform Apply
      │
      ▼
Create Database EC2 Instances
      │
      ▼
Copy bootstrap.sh via terraform_data
      │
      ▼
Install Ansible
      │
      ▼
Ansible Fetches Secrets from SSM
      │
      ▼
Run Ansible Playbooks
      │
      ▼
Configure Database Services
      │
      ▼
Create Route53 DNS Records
```

**Route53 Service Discovery:**

Each database instance automatically registers a DNS record:

```
mongodb-dev.servicewiz.in
redis-dev.servicewiz.in
mysql-dev.servicewiz.in
rabbitmq-dev.servicewiz.in
```

This enables services to communicate using **DNS names instead of IP addresses**.

**Terraform Dynamic Infrastructure:**

Database instances are created using Terraform `for_each` loops:

```hcl
for_each = local.databases
```

Benefits: Reduces duplicate code, simplifies expansion, and centralizes configuration.

---

### 50-backend-alb

Creates an **Internal Application Load Balancer (ALB)** used to route traffic between backend microservices.

This load balancer acts as the **internal traffic router for all application services**.

**Resources Created:**

| Resource | Type | Purpose |
|---|---|---|
| `aws_lb` | Internal ALB | Load balances backend traffic |
| `aws_lb_listener` | HTTP Listener (port 80) | Entry point for requests |
| `aws_route53_record` | Wildcard DNS | Routes `*.backend-alb-dev` to ALB |

**Terraform Example:**

```hcl
resource "aws_lb" "backend_alb" {
  name               = "${var.project}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.backend_alb_sg_id]
  subnets            = local.private_subnet_ids
}
```

| Field | Value | Meaning |
|---|---|---|
| `internal` | `true` | Only accessible inside VPC |
| `load_balancer_type` | `application` | Layer 7 (HTTP/HTTPS) load balancer |
| `security_groups` | Retrieved from SSM | Controls access to ALB |
| `subnets` | Private subnets | Deployed across multiple AZs |

**Listener with Default Action:**

```hcl
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hi, I am from HTTP Backend ALB</h1>"
      status_code  = "200"
    }
  }
}
```

> The default action handles requests that **don't match any routing rule**, preventing undefined behavior.

**Traffic Flow:**

```
Frontend Service
      │
      ▼
Backend ALB (Internal)
      │
      ▼
Listener (HTTP :80)
      │
      ▼
Listener Rules (Host-based routing)
      │
      ├── catalogue.backend-alb-dev.* → Catalogue Target Group
      ├── user.backend-alb-dev.*      → User Target Group
      ├── cart.backend-alb-dev.*      → Cart Target Group
      ├── shipping.backend-alb-dev.*  → Shipping Target Group
      └── payment.backend-alb-dev.*   → Payment Target Group
      │
      ▼
Healthy Backend Instances
```

---

## 📦 Terraform Modules

Reusable modules are stored under the **modules/** directory.

### terraform-aws-vpc

Reusable module for provisioning:

- VPC
- Subnets (Public, Private, Database)
- Internet Gateway, NAT Gateway
- Route Tables and Associations

### terraform-aws-sg

Reusable module for creating AWS Security Groups with configurable:

- Ingress/Egress rules
- Description and naming
- Tag management

> Using modules allows infrastructure to remain **consistent, reusable, and scalable**.

---

## 🔗 SSM Parameter Store Integration

Infrastructure values created in earlier layers are stored in **AWS Systems Manager Parameter Store** and read by subsequent layers using **Terraform data sources**.

**Example Parameters:**

```
/roboshop/dev/vpc_id
/roboshop/dev/public_subnet_ids
/roboshop/dev/private_subnet_ids
/roboshop/dev/bastion_sg_id
/roboshop/dev/backend_alb_sg_id
/roboshop/dev/catalogue_sg_id
```

**How It Works:**

```
┌─────────────────────────┐          ┌─────────────────────────┐
│   Terraform Layer A     │          │   Terraform Layer B     │
│   (00-vpc)              │          │   (50-backend-alb)      │
│                         │          │                         │
│   Creates:              │          │   Reads:                │
│   - VPC                 │──SSM───▶ │   - vpc_id              │
│   - Subnets             │  Store   │   - private_subnet_ids  │
│   - Security Groups     │          │   - backend_alb_sg_id   │
└─────────────────────────┘          └─────────────────────────┘
```

**Terraform Usage:**

```hcl
# Data source reads existing parameter
data "aws_ssm_parameter" "vpc_id" {
  name = "/roboshop/dev/vpc_id"
}

# Local variable for cleaner code
locals {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}
```

**Benefits:**

| Benefit | Explanation |
|---|---|
| **Loose coupling** | Layers don't depend on each other's state files |
| **Independent deployments** | Change VPC without re-running ALB terraform |
| **Team independence** | Different teams can own different layers |
| **CI/CD friendly** | Each layer has its own pipeline |
| **No state file sharing** | Avoids remote state data source complexity |

---

## 🔐 Secure Secret Management (SSM + IAM)

Sensitive data such as database passwords are **never** stored in Terraform code or Git repositories.

**Security Architecture:**

```
SSM Parameter Store (SecureString)
         │
         ▼
IAM Role attached to MySQL EC2
         │
         ▼
Ansible boto3 lookup
         │
         ▼
Retrieve secret securely
         │
         ▼
Configure MySQL root password
```

**Example parameter:**

```
/roboshop/dev/mysql_root_password  (SecureString)
```

**IAM Resources Used:**

```hcl
aws_iam_role                    # Role for EC2
aws_iam_policy                  # Policy allowing SSM access
aws_iam_role_policy_attachment  # Attach policy to role
aws_iam_instance_profile        # Attach role to EC2
```

**Why This Approach:**

- ✅ No credentials stored on servers
- ✅ Temporary credentials via IAM (auto-rotated)
- ✅ Audit trail via CloudTrail
- ✅ Encryption at rest via KMS
- ✅ Fine-grained access control

---

## 🌐 Wildcard DNS Routing

Route53 wildcard DNS record enables dynamic routing for multiple backend services through a single ALB.

**DNS Record:**

```
*.backend-alb-dev.servicewiz.in → Backend ALB (Alias Record)
```

**This Resolves:**

```
catalogue.backend-alb-dev.servicewiz.in  ──┐
user.backend-alb-dev.servicewiz.in       ──┤
cart.backend-alb-dev.servicewiz.in       ──┤──→  Same Backend ALB
shipping.backend-alb-dev.servicewiz.in   ──┤
payment.backend-alb-dev.servicewiz.in    ──┘
```

All traffic reaches the **Backend ALB**, where **listener rules** determine which target group (and therefore which microservice) receives the request.

---

## 🚢 Deployment Workflow

Infrastructure should be deployed **layer by layer** in the following order:

```
Step 1 → 00-vpc           (VPC, Subnets, Gateways)
Step 2 → 10-sg            (Security Groups)
Step 3 → 20-sg-rules      (Security Group Rules)
Step 4 → 30-bastion       (Bastion Host)
Step 5 → 40-databases     (MongoDB, Redis, MySQL, RabbitMQ)
Step 6 → 50-backend-alb   (Internal Load Balancer)
```

**Execution Flow:**

```
Terraform Apply
      │
      ▼
Create VPC & Networking
      │
      ▼
Create Security Groups
      │
      ▼
Apply Security Group Rules
      │
      ▼
Create Bastion Host
      │
      ▼
Create Database Instances + Ansible Config
      │
      ▼
Create Backend ALB + Listener + DNS
```

**Terraform Commands:**

```bash
# Initialize terraform (first time or after module changes)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# If modules are updated
terraform init -upgrade
```

---

## ✅ Key DevOps Concepts Implemented

| Concept | Implementation |
|---|---|
| Infrastructure as Code | Terraform for all resource provisioning |
| Modular Design | Reusable VPC and SG modules |
| Layered Architecture | Numbered layers with clear dependencies |
| Security Group Routing | SG references instead of IP addresses |
| Bastion Host Pattern | Secure entry point to private resources |
| Dynamic Resource Creation | Terraform `for_each` loops |
| Bootstrap Automation | `terraform_data` + Ansible playbooks |
| IAM Role-Based Access | No static credentials on servers |
| Secret Management | SSM Parameter Store (SecureString) |
| Configuration Management | Ansible roles for database setup |
| DNS Service Discovery | Route53 records for all services |
| Internal Load Balancing | Backend ALB for microservice routing |
| Wildcard DNS Routing | Single DNS record for all backend services |
| Infrastructure Decoupling | SSM Parameter Store between layers |
| Immutable Infrastructure | Replace instances, don't patch |

---
---

## 🔮 Future Enhancements

This repository is designed to grow into a **complete production-style DevOps infrastructure**.

| Enhancement | Status |
|---|---|
| Application EC2 Instances | 🔜 Planned |
| Target Groups | 🔜 Planned |
| Listener Rules (Host-based routing) | 🔜 Planned |
| Launch Templates | 🔜 Planned |
| Auto Scaling Groups | 🔜 Planned |
| Frontend ALB | 🔜 Planned |
| Kubernetes (EKS) | 🔜 Planned |
| CI/CD Pipelines (Jenkins/GitHub Actions) | 🔜 Planned |
| Monitoring & Logging (CloudWatch/Prometheus) | 🔜 Planned |
| WAF & DDoS Protection | 🔜 Planned |
| Cost Optimization (Spot Instances, Reserved) | 🔜 Planned |

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| **Terraform** | Infrastructure provisioning (IaC) |
| **AWS** | Cloud platform |
| **Ansible** | Configuration management |
| **Route53** | DNS & service discovery |
| **ALB** | Application load balancing |
| **SSM Parameter Store** | Infrastructure value sharing & secrets |
| **IAM** | Role-based access control |
| **VPC** | Network isolation & security |

---

## 📄 License

This project is licensed under the terms of the LICENSE file included in this repository.

---

## 👨‍💻 Author

**Ramu Chelloju**
DevOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ramuchelloju/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/chellojuramu)
