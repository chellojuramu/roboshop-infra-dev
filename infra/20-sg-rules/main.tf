# ============================================================================
# BASTION HOST SECURITY GROUP RULES
# ============================================================================
# Purpose: Bastion acts as a jump server to SSH into private instances
# This rule allows SSH access to the Bastion host from your specific IP only

resource "aws_security_group_rule" "bastion_internet" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  #cidr_blocks       = ["0.0.0.0/0"]
  cidr_blocks       = [local.my_ip]
  # which SG you are creating this rule
  security_group_id = local.bastion_sg_id
}

# ============================================================================
# MONGODB SECURITY GROUP RULES
# ============================================================================
# MongoDB is a NoSQL database used by catalogue and user services
# Port 27017 is the default MongoDB port


resource "aws_security_group_rule" "mongodb_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = local.bastion_sg_id
  # which SG you are creating this rule
  security_group_id = local.mongodb_sg_id
}
resource "aws_security_group_rule" "mongodb_catalogue" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.catalogue_sg_id

  security_group_id = local.mongodb_sg_id
}
resource "aws_security_group_rule" "mongodb_user" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.user_sg_id

  security_group_id = local.mongodb_sg_id
}

# ============================================================================
# REDIS SECURITY GROUP RULES
# ============================================================================
# Redis is an in-memory cache used by user and cart services
# Port 6379 is the default Redis port

resource "aws_security_group_rule" "redis_bastion" {
  type = "ingress"
  from_port         = 22
  to_port =           22
  protocol          = "tcp"
    source_security_group_id = local.bastion_sg_id
  security_group_id = local.redis_sg_id
}
resource "aws_security_group_rule" "redis_user" {
 type = "ingress"
  from_port         = 6379
  to_port =           6379
  protocol          = "tcp"
  source_security_group_id = local.user_sg_id
  security_group_id = local.redis_sg_id
}
resource "aws_security_group_rule" "redis_cart" {
  type = "ingress"
  from_port         = 6379
  to_port =           6379
  protocol          = "tcp"
  source_security_group_id = local.cart_sg_id
  security_group_id = local.redis_sg_id
}

# ============================================================================
# MYSQL SECURITY GROUP RULES
# ============================================================================
# MySQL is a relational database used by the shipping service
# Port 3306 is the default MySQL port

resource "aws_security_group_rule" "mysql_bastion" {
  type = "ingress"
  from_port         = 22
  to_port =           22
  protocol          = "tcp"
  #where traffic is coming from
    source_security_group_id = local.bastion_sg_id
    security_group_id = local.mysql_sg_id
}

resource "aws_security_group_rule" "mysql_shipping" {
  type = "ingress"
  from_port         = 3306
  to_port =           3306
  protocol          = "tcp"
  #where traffic is coming from
    source_security_group_id = local.shipping_sg_id
    security_group_id = local.mysql_sg_id
}
# ============================================================================
# RABBITMQ SECURITY GROUP RULES
# ============================================================================
# RabbitMQ is a message queue used by the payment service for async processing
# Port 5672 is the default RabbitMQ AMQP port

# Rule 1: Allow SSH from Bastion to RabbitMQ instances

resource "aws_security_group_rule" "rabbitmq_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.bastion_sg_id
  security_group_id = local.rabbitmq_sg_id
}
resource "aws_security_group_rule" "rabbitmq_payment" {
  type                     = "ingress"
  from_port                = 5672
  to_port                  = 5672
  protocol = "tcp"
  #where traffic is coming from
  source_security_group_id = local.payment_sg_id
  security_group_id        = local.rabbitmq_sg_id
}

# ============================================================================
# CATALOGUE SERVICE SECURITY GROUP RULES
# ============================================================================
# Catalogue is a backend microservice that manages product catalog
# It runs on port 8080 and is accessed via the Backend ALB

resource "aws_security_group_rule" "catalogue_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.bastion_sg_id
  security_group_id = local.catalogue_sg_id
}
resource "aws_security_group_rule" "catalogue_backend_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.backend_alb_sg_id
  security_group_id = local.catalogue_sg_id
}


# ============================================================================
# USER SERVICE SECURITY GROUP RULES
# ============================================================================
# User is a backend microservice that manages user authentication and profiles
# It runs on port 8080 and is accessed via the Backend ALB

resource "aws_security_group_rule" "user_bastion" {
 type = "ingress"
  from_port         = 22
  to_port =           22
  protocol          = "tcp"
  # Where traffic is coming from
    source_security_group_id = local.bastion_sg_id
    security_group_id = local.user_sg_id
}
resource "aws_security_group_rule" "user_backend_alb" {
  type = "ingress"
  from_port         = 8080
  to_port =           8080
  protocol          = "tcp"
  # Where traffic is coming from
    source_security_group_id = local.backend_alb_sg_id
    security_group_id = local.user_sg_id
}
# ============================================================================
# CART SERVICE SECURITY GROUP RULES
# ============================================================================
# Cart is a backend microservice that manages shopping cart operations
# It runs on port 8080 and is accessed via the Backend ALB

resource "aws_security_group_rule" "cart_bastion" {
  type = "ingress"
    from_port         = 22
    to_port =           22
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.bastion_sg_id
    security_group_id = local.cart_sg_id
}

resource "aws_security_group_rule" "cart_backend_alb" {
  type = "ingress"
    from_port         = 8080
    to_port =           8080
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.backend_alb_sg_id
    security_group_id = local.cart_sg_id
}
# ============================================================================
# SHIPPING SERVICE SECURITY GROUP RULES
# ============================================================================
# Shipping is a backend microservice that handles order shipping logistics
# It runs on port 8080 and is accessed via the Backend ALB

resource "aws_security_group_rule" "shipping_bastion" {
 type = "ingress"
    from_port         = 22
    to_port =           22
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.bastion_sg_id
    security_group_id = local.shipping_sg_id
}
resource "aws_security_group_rule" "shipping_backend_alb" {
  type = "ingress"
    from_port         = 8080
    to_port =           8080
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.backend_alb_sg_id
    security_group_id = local.shipping_sg_id
}
# ============================================================================
# PAYMENT SERVICE SECURITY GROUP RULES
# ============================================================================
# Payment is a backend microservice that processes payment transactions
# It runs on port 8080 and is accessed via the Backend ALB

resource "aws_security_group_rule" "payment_bastion" {
  type = "ingress"
    from_port         = 22
    to_port =           22
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.bastion_sg_id
    security_group_id = local.payment_sg_id
}
resource "aws_security_group_rule" "payment_backend_alb" {
    type = "ingress"
        from_port         = 8080
        to_port =           8080
        protocol          = "tcp"
        # Where traffic is coming from
        source_security_group_id = local.backend_alb_sg_id
        security_group_id = local.payment_sg_id
}
# ============================================================================
# BACKEND ALB (INTERNAL LOAD BALANCER) SECURITY GROUP RULES
# ============================================================================
# Backend ALB distributes traffic to all backend microservices
# It accepts traffic on port 80 from frontend and other backend services

resource "aws_security_group_rule" "backend_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.bastion_sg_id
  security_group_id = local.backend_alb_sg_id
}
resource "aws_security_group_rule" "backend_alb_catalogue" {
 type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
    source_security_group_id = local.catalogue_sg_id
    security_group_id = local.backend_alb_sg_id
}
resource "aws_security_group_rule" "backend_alb_user" {
  type = "ingress"
    from_port         = 80
    to_port =           80
    protocol          = "tcp"
    # Where traffic is coming from
    source_security_group_id = local.user_sg_id
    security_group_id = local.backend_alb_sg_id
}
resource "aws_security_group_rule" "backend_alb_cart" {
  type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.cart_sg_id
  security_group_id = local.backend_alb_sg_id
}

resource "aws_security_group_rule" "backend_alb_shipping" {
  type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.shipping_sg_id
  security_group_id = local.backend_alb_sg_id
}

resource "aws_security_group_rule" "backend_alb_payment" {
  type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.payment_sg_id
  security_group_id = local.backend_alb_sg_id
}
resource "aws_security_group_rule" "backend_alb_frontend" {
  type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.frontend_sg_id
  security_group_id = local.backend_alb_sg_id
}
# ============================================================================
# FRONTEND SERVICE SECURITY GROUP RULES
# ============================================================================
# Frontend serves the web UI (HTML/CSS/JS) to users
# It runs on port 80 and is accessed via the Frontend ALB
# Rule 1: Allow SSH from Bastion to Frontend instances
resource "aws_security_group_rule" "frontend_bastion" {
  type                     = "ingress"             # Allowing incoming traffic
  from_port                = 22                    # SSH port
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = local.bastion_sg_id   # Traffic source: Bastion host
  security_group_id        = local.frontend_sg_id  # Adding rule TO: Frontend security group
}
resource "aws_security_group_rule" "frontend_frontend_alb" {
  type = "ingress"
  from_port         = 80
  to_port =           80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.frontend_alb_sg_id
  security_group_id = local.frontend_sg_id
}
# ============================================================================
# FRONTEND ALB (PUBLIC LOAD BALANCER) SECURITY GROUP RULES
# ============================================================================
# Frontend ALB is the public entry point for all user traffic
# It accepts HTTPS traffic from the internet on port 443

resource "aws_security_group_rule" "frontend_alb_public" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  # Where traffic is coming from
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = local.frontend_alb_sg_id
}
#OPENVPN
resource "aws_security_group_rule" "openvpn_public_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  # Where traffic is coming from
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = local.openvpn_sg_id
}
#adminui openvpn
resource "aws_security_group_rule" "openvpn_public_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  # Where traffic is coming from
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = local.openvpn_sg_id
}
resource "aws_security_group_rule" "backend_alb_openvpn" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  # Where traffic is coming from
  source_security_group_id = local.openvpn_sg_id
  security_group_id = local.backend_alb_sg_id
}