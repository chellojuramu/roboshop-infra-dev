# roboshop-infra-dev

Infrastructure as Code (IaC) repository for provisioning the **Roboshop application infrastructure** using **Terraform and AWS**.

This repository follows a **modular and layered infrastructure design**, allowing components to be created, managed, and extended independently.

The goal of this project is to build a **production-style DevOps infrastructure architecture** that can evolve over time with additional services such as compute layers, load balancers, Kubernetes clusters, CI/CD pipelines, monitoring, and more.

---

# Project Architecture

This repository is organized into **two main sections**:

```
roboshop-infra-dev
│
├── infra
│   ├── 00-vpc
│   ├── 10-sg
│   ├── 20-sg-rules
│   ├── 30-bastion
│   └── 40-databases
│
├── modules
│   ├── terraform-aws-vpc
│   └── terraform-aws-sg
```

---

# Infrastructure Layers

The infrastructure is created in **logical layers**, where each layer depends on the previous one.

## 00-vpc

Creates the foundational networking components:
- VPC
- Public Subnets
- Private Subnets
- Database Subnets
- Internet Gateway
- NAT Gateway

Key outputs such as **VPC ID and Subnet IDs** are stored in **AWS Systems Manager Parameter Store** for use by other modules.

---

## 10-sg

Creates **security groups** for the application components.

Examples include:

* mongodb
* redis
* mysql
* rabbitmq
* catalogue
* user
* cart
* shipping
* payment
* backend_alb
* frontend
* frontend_alb
* bastion

Security group IDs are stored in **SSM Parameter Store** to enable cross-module usage.

---

## 20-sg-rules

Defines the **network communication rules** between services.

Examples:

* Bastion → MongoDB (SSH)
* Catalogue → MongoDB
* User → MongoDB
* Bastion → Redis

Security group rules enforce controlled communication between application services.

---

## 30-bastion

Creates a **Bastion Host EC2 instance** used to securely access private infrastructure resources.

Features:

* EC2 instance in public subnet
* IAM role attached via instance profile
* Security group restricting SSH access to a specific IP
* Custom root volume configuration
* Bootstrap script using provisioners
* Secure entry point into private subnets
* Infrastructure management from inside the VPC

# 40-databases

Creates the database infrastructure.

**Resources:**
* MongoDB EC2 instance
* Redis EC2 instance
* MySQL EC2 instance
* RabbitMQ EC2 instance

**Features:**
* Instances launched in database subnets
* Security groups applied dynamically using `for_each`
* Route53 DNS records automatically created
* Instance configuration handled using Terraform `terraform_data`
* Ansible used for service configuration
* IAM Role attached to MySQL instance for secure secret retrieval

**Configuration flow:**
```
Terraform
   │
   ▼
Create Database EC2 Instances
   │
   ▼
Copy bootstrap.sh
   │
   ▼
Install Ansible
   │
   ▼
Run Ansible Playbooks
   │
   ▼
Configure Databases
```

## Secure Secret Management (SSM + IAM)

Sensitive data such as database passwords are not stored in Terraform code or Git repositories.

Instead, secrets are stored in AWS Systems Manager Parameter Store.

**Example parameter:**
```
/roboshop/dev/mysql_root_password
```

**Security architecture:**
```
SSM Parameter Store
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

This approach follows production-grade secret management practices.

## IAM Role for Database Access

MySQL EC2 instances are assigned an IAM Role via Instance Profile.

**Purpose:**
* Allow EC2 instances to securely access SSM Parameter Store
* Avoid storing AWS credentials inside servers
* Enable temporary credential usage via IAM

**Terraform resources used:**
```
aws_iam_role
aws_iam_policy
aws_iam_role_policy_attachment
aws_iam_instance_profile
```

This enables secure AWS API access from EC2 instances.

## Ansible-Based Service Configuration

Database services are configured using Ansible roles executed during bootstrap.

**Bootstrap process:**
```
bootstrap.sh
      │
      ▼
Install Ansible
      │
      ▼
Clone Ansible roles repository
      │
      ▼
Run playbook with component variable
```

**Example command executed by Terraform:**
```
sudo sh /tmp/bootstrap.sh mysql dev
```

Ansible then configures the required service.

## Route53 Service Discovery

Each database instance automatically registers a DNS record.

**Example:**
```
mongodb-dev.servicewiz.in
redis-dev.servicewiz.in
mysql-dev.servicewiz.in
rabbitmq-dev.servicewiz.in
```

This enables services to communicate using DNS instead of IP addresses.

**Example connection test:**
```
mysql -h mysql-dev.servicewiz.in -u root -p
```

## Terraform Dynamic Infrastructure

Database instances are created using Terraform `for_each` loops.

**Example pattern:**
```
for_each = local.databases
```

**Benefits:**
* Reduces duplicate code
* Simplifies infrastructure expansion
* Allows centralized configuration of multiple services

**Example database map:**
```
mongodb
redis
mysql
rabbitmq
```

## Configuration Automation Flow

Complete automation flow implemented:
```
Terraform Apply
      │
      ▼
Create Infrastructure
      │
      ▼
Attach IAM Roles
      │
      ▼
Launch Database Instances
      │
      ▼
Bootstrap Script Execution
      │
      ▼
Install Ansible
      │
      ▼
Ansible Fetches Secrets from SSM
      │
      ▼
Configure Database Services
      │
      ▼
Create Route53 DNS Records
```

## Key DevOps Concepts Implemented

* Infrastructure as Code (Terraform)
* Modular infrastructure design
* Security group based microservice communication
* Bastion host access pattern
* Terraform dynamic resource creation (`for_each`)
* Terraform `terraform_data` bootstrap pattern
* IAM Role based secure AWS access
* Secret management using AWS SSM Parameter Store
* Ansible configuration management
* DNS based service discovery using Route53
* Secure database password provisioning
---

# Terraform Modules

Reusable modules are stored under the **modules/** directory.

## terraform-aws-vpc

Reusable module for provisioning:

* VPC
* Subnets
* Networking components

## terraform-aws-sg

Reusable module for creating AWS Security Groups.

Using modules allows infrastructure to remain **consistent, reusable, and scalable**.

---

# Parameter Store Usage

This project uses **AWS Systems Manager Parameter Store** to share infrastructure values across modules.

Examples:

```
/roboshop/dev/vpc_id
/roboshop/dev/public_subnet_ids
/roboshop/dev/bastion_sg_id
```

This approach avoids hardcoding values and enables **loose coupling between Terraform layers**.

---

# Deployment Workflow

Infrastructure should be deployed **layer by layer** in the following order:

```
1. 00-vpc
2. 10-sg
3. 20-sg-rules
4. 30-bastion
5. 40-databases
```
## Execution Flow

```
Terraform Apply
      │
      ▼
Create VPC
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
Create Database Instances
      │
      ▼
Bootstrap Configuration
      │
      ▼
Install Services (MongoDB / Redis)
```
Typical Terraform workflow:

```
terraform init
terraform plan
terraform apply
```

If modules change:

```
terraform init -upgrade
```

## Key DevOps Concepts Implemented

- Infrastructure as Code (IaC)
- Modular Terraform design
- Remote state management
- Secure infrastructure with private subnets
- Bastion access pattern
- Automated server configuration
- Service discovery using DNS

---


# Future Enhancements

This repository is designed to grow into a **complete production-style DevOps infrastructure**.

Planned additions may include:

* Application EC2 instances
* Load Balancers (ALB/NLB)
* Kubernetes (EKS)
* CI/CD pipelines
* Monitoring and logging
* Infrastructure automation
* Cost optimization

---

# Technologies Used

* Terraform
* AWS
* Infrastructure as Code (IaC)
* Modular DevOps Architecture

---

# License

This project is licensed under the terms of the LICENSE file included in this repository.
## Author

Ramu Chelloju

DevOps Engineer