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

## 📝 FAANG Interview Reference

This project demonstrates real-world infrastructure patterns commonly tested in **FAANG / Big Tech interviews** for DevOps, SRE, Cloud Infrastructure, and Platform Engineering roles.

### Architecture & Load Balancing

<details>
<summary><strong>Q: Why do large systems use two load balancers (Frontend + Backend)?</strong></summary>

To **separate internet traffic from internal service communication**:

- **Frontend ALB** (internet-facing) — handles user-facing traffic in public subnets
- **Backend ALB** (internal) — handles service-to-service traffic in private subnets

Benefits: Security isolation, independent scaling, cleaner routing rules, reduced attack surface.

This is the same pattern used at **Amazon, Netflix, and Google** scale:

```
Edge LB / CDN → API Gateway → Internal LB → Microservices → Databases
```
</details>

<details>
<summary><strong>Q: Difference between internal and internet-facing ALB?</strong></summary>

| Feature | Internet-Facing | Internal |
|---|---|---|
| DNS | Public DNS name | Private DNS name |
| Subnets | Public subnets | Private subnets |
| Accessible from | Internet + VPC | VPC only |
| Use case | User-facing traffic | Service-to-service |
| Security | Needs WAF, rate limiting | VPC-level isolation |
</details>

<details>
<summary><strong>Q: What happens when a request hits ALB?</strong></summary>

1. Request arrives at the **listener** on the configured port
2. Listener evaluates rules in **priority order** (lowest number = highest priority)
3. First matching rule's **action** is executed
4. If no rule matches, the **default action** runs
5. Action forwards to a target group or returns a fixed/redirect response
6. Target group selects a healthy instance using the configured algorithm (round-robin by default)
</details>

<details>
<summary><strong>Q: When would you choose NLB over ALB?</strong></summary>

- **Ultra-low latency** requirements (NLB operates at Layer 4)
- Need for **static IP addresses** or **Elastic IPs** on the load balancer
- **TCP/UDP** protocols (non-HTTP traffic like databases, gaming, IoT)
- **Millions of requests per second** — NLB handles extreme throughput
- **gRPC** traffic that needs direct TCP passthrough
</details>

<details>
<summary><strong>Q: How does ALB handle SSL/TLS termination?</strong></summary>

ALB terminates SSL at the load balancer level using ACM certificates:

- Client → ALB: **Encrypted (HTTPS)**
- ALB → Backend: **Unencrypted (HTTP)** or re-encrypted
- Reduces CPU load on backend instances
- Centralized certificate management
- For end-to-end encryption, configure ALB to forward HTTPS to instances
</details>

### Security & Networking

<details>
<summary><strong>Q: Why must backend instances allow traffic from ALB security group?</strong></summary>

ALB forwards requests to backend instances on their application port. Without an ingress rule allowing the **ALB's security group** as the source:

- Application traffic is **blocked**
- Health checks **fail**
- ALB marks all targets as **unhealthy**
- Service becomes **completely unreachable**

We reference SGs instead of IPs because ALB IPs change dynamically.
</details>

<details>
<summary><strong>Q: Security Group vs NACL — what's the difference?</strong></summary>

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance (ENI) | Subnet |
| State | **Stateful** (return traffic auto-allowed) | **Stateless** (must allow both directions) |
| Rules | Allow only | Allow + Deny |
| Evaluation | All rules evaluated | Rules evaluated in order |
| Default | Deny all inbound | Allow all |
</details>

<details>
<summary><strong>Q: How would you implement zero-trust networking in AWS?</strong></summary>

- **Security Groups** — Whitelist only required source SGs per service
- **NACLs** — Subnet-level deny rules for known bad IPs
- **VPC Endpoints** — Access AWS services without internet
- **PrivateLink** — Expose services without VPC peering
- **mTLS** — Mutual TLS between services (service mesh like Istio)
- **IAM Roles** — No static credentials, instance-based roles
- **Encryption** — In transit (TLS) and at rest (KMS)
</details>

<details>
<summary><strong>Q: A developer says their app can't connect to the database. How do you troubleshoot?</strong></summary>

Systematic approach:

1. **Security Groups** — App SG allows outbound? DB SG allows inbound from app SG?
2. **NACLs** — Subnet-level rules blocking traffic?
3. **Route Tables** — App subnet can route to DB subnet?
4. **DNS Resolution** — App can resolve DB endpoint?
5. **DB Status** — RDS instance running and accepting connections?
6. **DB Auth** — Credentials correct? User authorized?
7. **VPC Flow Logs** — Check for rejected packets
8. **Application Logs** — What error message?
</details>

### DNS & Service Discovery

<details>
<summary><strong>Q: What is wildcard DNS and when would you use it?</strong></summary>

A wildcard DNS record uses `*` to match **any subdomain** that doesn't have an explicit record. Use it when:

- Multiple microservices share the same load balancer
- You want to avoid creating individual DNS records per service
- Combined with ALB host-based routing for dynamic service discovery
</details>

<details>
<summary><strong>Q: What is the difference between A record, CNAME, and Alias record?</strong></summary>

| Record | Points To | Root Domain? | AWS-Specific |
|---|---|---|---|
| **A** | IP address | ✅ Yes | No |
| **CNAME** | Another domain name | ❌ No | No |
| **Alias** | AWS resource (ALB, S3, CF) | ✅ Yes | Yes |

Alias is preferred for AWS resources — it's **free** (no query charges), supports **root domains**, and resolves directly.
</details>

<details>
<summary><strong>Q: How does DNS failover work for disaster recovery?</strong></summary>

Configure Route53 **failover routing policy**:

- **Primary** record → Production ALB in us-east-1 (with health check)
- **Secondary** record → DR ALB in us-west-2
- If primary health check fails, Route53 automatically routes to secondary
- TTL should be low (60s) for faster failover
</details>

### Target Groups & Health Checks

<details>
<summary><strong>Q: What types of targets can a target group contain?</strong></summary>

- **EC2 Instances** — Traditional deployments
- **IP Addresses** — ECS Fargate, cross-VPC
- **Lambda Functions** — Serverless backends
- **Containers** — ECS/EKS tasks

Target type is set at creation and **cannot be changed**.
</details>

<details>
<summary><strong>Q: Why are health checks important in load balancing?</strong></summary>

Health checks ensure traffic is routed **only to healthy instances**. Without them:

- Users would hit failed instances → **5xx errors**
- No automatic recovery mechanism
- Manual intervention required for every failure
- Cascading failures across dependent services

ALB health checks: `3 success → healthy`, `2 failures → unhealthy`
</details>

<details>
<summary><strong>Q: Health checks are failing but the app works when you SSH in. What's wrong?</strong></summary>

1. **Security Group** — ALB SG not allowed on health check port
2. **Health check path** — `/health` endpoint doesn't exist or returns non-200
3. **Port mismatch** — Health check port ≠ application port
4. **Timeout too low** — App takes longer to respond than timeout
5. **Application binding** — App listening on `127.0.0.1` instead of `0.0.0.0`
6. **Dependency failure** — Health endpoint checks DB, DB is slow
</details>

<details>
<summary><strong>Q: How would you design a health check endpoint?</strong></summary>

A good `/health` endpoint should:

- Return **200** if the service can handle requests
- Check critical dependencies (DB, cache, message queue)
- Have **shallow** and **deep** health checks:
  - `/health` → Quick check (is the process running?)
  - `/health/ready` → Readiness (are dependencies connected?)
  - `/health/live` → Liveness (is the process responsive?)
- Respond within **2 seconds**
- **Never** cache the response
</details>

### Auto Scaling & Compute

<details>
<summary><strong>Q: Launch Template vs Launch Configuration?</strong></summary>

| Feature | Launch Template | Launch Configuration |
|---|---|---|
| Versioning | ✅ Yes | ❌ No |
| Multiple instance types | ✅ Yes | ❌ No |
| Spot + On-Demand mix | ✅ Yes | ❌ No |
| Modifiable | ✅ New versions | ❌ Immutable |
| Status | **Current** | **Legacy (deprecated)** |
</details>

<details>
<summary><strong>Q: Why is auto scaling important?</strong></summary>

- **High availability** — Maintains minimum instances, replaces failed ones
- **Cost efficiency** — Scale in during low traffic
- **Performance** — Scale out before degradation
- **Self-healing** — Automatically replaces unhealthy instances

Scaling policies: Target Tracking, Step Scaling, Scheduled, Predictive
</details>

<details>
<summary><strong>Q: ASG keeps launching and terminating instances in a loop. What's happening?</strong></summary>

This is **scaling thrashing**. Common causes:

1. Health check misconfiguration — instances marked unhealthy immediately
2. Application boot time > health check grace period
3. Insufficient instance size — new instance hits CPU limit immediately
4. Conflicting scaling policies — scale-out and scale-in thresholds too close

Fix: Increase health check grace period, use correct instance type, add cooldown periods.
</details>

### Deployment Strategies

<details>
<summary><strong>Q: What is rolling deployment?</strong></summary>

Gradually replaces old instances with new ones in batches:

```
10 instances running v3
Batch 1: 4 instances → v4    [4 v4 + 6 v3]
Batch 2: 4 instances → v4    [8 v4 + 2 v3]
Batch 3: 2 instances → v4    [10 v4]
```

✅ Zero downtime | ⚠️ Mixed versions during deployment | ❌ Slow rollback
</details>

<details>
<summary><strong>Q: Compare all deployment strategies</strong></summary>

| Strategy | Downtime | Rollback Speed | Cost | Risk |
|---|---|---|---|---|
| **Rolling** | None | Slow | No extra | Medium |
| **Blue/Green** | None | Instant | 2x infra | Low |
| **Canary** | None | Fast | Minimal | Lowest |
| **Recreate** | Yes | Slow | No extra | High |
</details>

<details>
<summary><strong>Q: Deploying a critical payment service — which strategy and why?</strong></summary>

**Canary deployment** because:

- Start with 1-5% traffic to new version
- Monitor error rates, latency, and business metrics (payment success rate)
- If any anomaly → instantly route 100% back to old version
- For payment services, **data integrity** > speed
- Combine with **feature flags** for even safer rollouts
</details>

### Terraform & IaC

<details>
<summary><strong>Q: What is the difference between resource and data in Terraform?</strong></summary>

- `resource` **creates and manages** infrastructure — Terraform tracks its lifecycle
- `data` **reads existing** infrastructure — read-only lookup, no management

```hcl
# WRITE — creates infrastructure
resource "aws_instance" "web" { ... }

# READ — looks up existing infrastructure
data "aws_ssm_parameter" "vpc_id" { ... }
```
</details>

<details>
<summary><strong>Q: How do you share outputs between Terraform layers?</strong></summary>

| Method | Coupling | Best For |
|---|---|---|
| **SSM Parameter Store** | Loose | Cross-team modules |
| **Remote State Data Source** | Tight | Same-team modules |
| **Terragrunt** | Medium | Complex dependencies |

This project uses **SSM Parameter Store** for maximum decoupling.
</details>

<details>
<summary><strong>Q: What is Terraform state and why is it critical?</strong></summary>

State is Terraform's **record of reality** — maps config to real infrastructure:

- Tracks resource IDs, attributes, dependencies
- Enables `plan` to show what will change
- Must be stored **remotely** (S3 + DynamoDB locking)
- **Never** edit state manually
- Sensitive data may be in state — encrypt at rest
</details>

<details>
<summary><strong>Q: What happens if someone manually changes Terraform-managed infrastructure?</strong></summary>

**Configuration drift.** On next `terraform plan`:

- Terraform compares state with real infrastructure
- Detects the difference
- Proposes changes to restore **desired state**
- `terraform apply` overwrites manual changes

Prevention: CI/CD pipelines for all changes, drift detection, resource locks.
</details>

<details>
<summary><strong>Q: How do you handle secrets in Terraform?</strong></summary>

Secrets should **never** be in code or state in plain text:

- **AWS Secrets Manager / SSM SecureString** — Store and reference
- **HashiCorp Vault** — Dynamic secrets
- **Environment variables** — `TF_VAR_` prefix
- **Encrypted state** — S3 with SSE-KMS
- **Never** commit `.tfvars` with secrets to Git
</details>

### Advanced Architecture

<details>
<summary><strong>Q: How would you design a multi-region DR architecture?</strong></summary>

| Strategy | RTO | Cost | Complexity |
|---|---|---|---|
| **Active-Active** | Near zero | Highest | Highest |
| **Active-Passive** | Minutes | High | Medium |
| **Warm Standby** | Minutes | Medium | Medium |
| **Pilot Light** | Hours | Low | Low |

Database: Cross-region replicas (Aurora Global, DynamoDB Global Tables)
DNS: Route53 failover or latency-based routing
</details>

<details>
<summary><strong>Q: High Availability vs Fault Tolerance?</strong></summary>

- **High Availability:** System stays operational with **minimal downtime** (e.g., multi-AZ — brief failover)
- **Fault Tolerance:** System continues with **zero downtime** even during failures (e.g., active-active multi-region)

Fault tolerance is more expensive and complex.
</details>

<details>
<summary><strong>Q: What is GitOps?</strong></summary>

Using **Git as the single source of truth** for infrastructure and application state:

- Changes via pull requests
- Automated reconciliation (desired state vs actual state)
- Full audit trail
- Tools: ArgoCD, Flux, Jenkins X
</details>

<details>
<summary><strong>Q: Mutable vs Immutable Infrastructure?</strong></summary>

| Approach | Description | Risk |
|---|---|---|
| **Mutable** | Update existing servers in place | Configuration drift |
| **Immutable** | Replace servers with new ones | Consistent, predictable |

This project follows **immutable infrastructure** — instances are replaced, not patched.
</details>

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
