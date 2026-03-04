# 🚀 Multi-AZ 3-Tier AWS VPC Architecture using Terraform

This project provisions a production-ready AWS networking architecture using Terraform.

It includes:

- Custom VPC
- Public, Private, and Database Subnets (Multi-AZ)
- Internet Gateway
- NAT Gateway with Elastic IP
- Route Tables and Associations
- Optional VPC Peering with Default VPC
- DNS Resolution Across Peered VPCs

---

# 🏗️ Architecture Overview

This project creates a standard 3-tier architecture:

Internet
↓
Internet Gateway
↓
Public Subnets (Load Balancer / NAT)
↓
Private Subnets (Application / EKS Nodes)
↓
Database Subnets (RDS)

Optional:
Custom VPC <——> Default VPC (via VPC Peering)

---

# 📦 Resources Created

## 1️⃣ VPC

- Custom CIDR block (var.vpc_cidr)
- DNS hostnames enabled
- Tagged using centralized tagging strategy

---

## 2️⃣ Subnets (Multi-AZ)

### Public Subnets
- One per Availability Zone
- Auto-assign public IP
- Route to Internet Gateway

### Private Subnets
- No public IP
- Route to NAT Gateway
- Used for App servers / EKS nodes

### Database Subnets
- Isolated layer
- Route to NAT (optional in production)
- Intended for RDS

Subnets are dynamically created using:
count = length(var.<subnet_cidrs>)


---

## 3️⃣ Internet Gateway (IGW)

Attached to VPC.

Allows public subnets to access the internet.

Route:0.0.0.0/0 → IGW


---

## 4️⃣ NAT Gateway + Elastic IP

Private subnets require outbound internet access.

Flow:
Private EC2 → NAT → EIP → Internet

### Elastic IP (EIP)
- Static public IP
- Attached to NAT
- Ensures fixed outbound IP

---

## 5️⃣ Route Tables

Three separate route tables:

- Public
- Private
- Database

Each subnet is explicitly associated with its route table.

Without association, routing does not work.

---

## 6️⃣ VPC Peering (Optional)

Controlled by variable:var.is_peering_required

If true:

- Creates peering connection between:
    - Custom VPC
    - Default VPC
- Enables private DNS resolution across VPCs
- Adds routes on BOTH VPCs

### Important:
Peering requires route entries in both VPC route tables.

---

# 🔁 Traffic Flow

## Public Traffic

User → Internet → IGW → Public Subnet

---

## Private Outbound Traffic

Private EC2 → Private Route Table → NAT → IGW → Internet

---

## Peered VPC Traffic

Custom VPC → Peering → Default VPC  
Default VPC → Peering → Custom VPC

No Internet involved.

---

# 🔑 Key Terraform Concepts Used

## count

Used for:
- Dynamic subnet creation
- Conditional peering creation

Example:count = var.is_peering_required ? 1 : 0

When count is used:
Resources become indexed lists:resource_name[0]

---

## count.index

Used to:
- Map subnets to AZs
- Align routes with peering
- Reference counted resources safely

---

## merge()

Used for:
- Combining common tags
- Resource-specific tags
- User override tags

---

## slice()

Used to:
- Limit availability zones
- Ensure consistent Multi-AZ deployment

---

# 🛡️ Security Model

| Layer      | Internet Access | Purpose |
|------------|-----------------|----------|
| Public     | Yes             | Load Balancer / NAT |
| Private    | Outbound Only   | Application Layer |
| Database   | Internal Only   | RDS Layer |

---

# ⚠️ Important Notes

- NAT Gateway is created in only one AZ (cost-optimized).
- For production HA, create one NAT per AZ.
- CIDR blocks must not overlap for VPC peering.
- Security Groups must allow traffic even if peering exists.
- Route tables must be configured on both VPCs for peering.

---

# 📁 Variables Used

- var.vpc_cidr
- var.public_subnet_cidrs
- var.private_subnet_cidrs
- var.database_subnet_cidrs
- var.project
- var.environment
- var.is_peering_required

---

# 🚀 Use Cases

- EKS Cluster Networking
- ECS Deployments
- EC2 Microservices
- RDS Deployments
- Multi-VPC Communication
- Migration from Default VPC

---

# 🧠 Interview Highlights

You should be able to explain:

- Difference between IGW and NAT
- Why private subnets need NAT
- Why route table association is mandatory
- Why peering needs routes on both sides
- Why EIP is required for NAT
- Difference between Public / Private / Database subnets

---

# 🏁 Summary

This project provisions a production-style AWS networking foundation with:

✔ Multi-AZ design  
✔ 3-tier isolation  
✔ Secure outbound access  
✔ Optional VPC peering  
✔ Reusable tagging strategy  
✔ Dynamic resource creation

It is suitable as a base networking module for:

- Kubernetes (EKS)
- Microservices
- Production web applications

---

# 👨‍💻 Author

Ramu Chelloju  
DevOps & Cloud Engineering Journey
