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
│   └── 30-bastion
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

* VPC
* Public Subnets
* Private Subnets
* Database Subnets

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

Security group rules enforce controlled communication between application services.

---

## 30-bastion

Creates a **Bastion Host EC2 instance** used to securely access private infrastructure resources.

Features:

* EC2 instance in public subnet
* IAM role attached via instance profile
* Security group restricting SSH access to a specific IP

This instance acts as a **secure entry point** for administrative access to private resources.

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
