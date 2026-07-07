terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                   = var.aws_region
  profile                  = var.aws_profile != "" ? var.aws_profile : null
  shared_credentials_files = var.aws_shared_credentials_file != "" ? [var.aws_shared_credentials_file] : null

  access_key = var.aws_access_key_id != "" ? var.aws_access_key_id : null
  secret_key = var.aws_secret_access_key != "" ? var.aws_secret_access_key : null
  token      = var.aws_session_token != "" ? var.aws_session_token : null
}

# ============================================
# DATA SOURCES
# ============================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# VPC - CREAR NUEVA VPC PARA LA APLICACIÓN
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "despacho-vpc"
    Project = "innovatech"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "despacho-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = { Name = "despacho-public-subnet-2" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "despacho-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "despacho-private-subnet-2" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "despacho-igw" }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "despacho-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "despacho-nat" }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "despacho-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "despacho-private-rt" }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# ============================================
# SECURITY GROUP PARA ALB - PÚBLICO
# ============================================

resource "aws_security_group" "alb_public" {
  name        = "despacho-alb-public"
  description = "Security group for ALB public access"
  vpc_id      = aws_vpc.main.id

  # Permitir HTTP desde cualquier dirección
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Permitir HTTPS desde cualquier dirección
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Permitir tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { Name = "despacho-alb-public-sg" }
}

# ============================================
# SECURITY GROUP PARA NODOS EKS
# ============================================

resource "aws_security_group" "eks_nodes" {
  name        = "despacho-eks-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico desde ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
    description     = "Allow HTTP from ALB"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
    description     = "Allow HTTPS from ALB"
  }

  # Permitir puertos de aplicación (8080, 8081, 3000)
  ingress {
    from_port       = 8080
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
    description     = "Allow backend ports from ALB"
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
    description     = "Allow frontend from ALB"
  }

  # Permitir comunicación entre nodos
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow inter-node communication"
  }

  # Permitir tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { Name = "despacho-eks-nodes-sg" }
}

# ============================================
# SECURITY GROUP PARA BASE DE DATOS
# ============================================

resource "aws_security_group" "database" {
  name        = "despacho-database"
  description = "Security group for RDS/MySQL"
  vpc_id      = aws_vpc.main.id

  # Permitir acceso MySQL desde nodos EKS
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "Allow MySQL from EKS nodes"
  }

  # Permitir tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { Name = "despacho-database-sg" }
}

# ============================================
# ECR REPOSITORIES
# ============================================

resource "aws_ecr_repository" "backend_despacho_repo" {
  name = "backend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags         = { Project = "innovatech" }
}

resource "aws_ecr_repository" "backend_ventas_repo" {
  name = "backend-ventas"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags         = { Project = "innovatech" }
}

resource "aws_ecr_repository" "frontend_despacho_repo" {
  name = "frontend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags         = { Project = "innovatech" }
}

# ============================================
# IAM ROLES FOR EKS CLUSTER
# ============================================

data "aws_iam_roles" "eks_cluster_candidates" {
  count      = var.eks_cluster_role_name == "" ? 1 : 0
  name_regex = ".*${var.eks_role_tag_filter}.*"
}

locals {
  eks_cluster_role_names         = length(data.aws_iam_roles.eks_cluster_candidates) > 0 ? tolist(data.aws_iam_roles.eks_cluster_candidates[0].names) : []
  eks_node_role_names            = length(data.aws_iam_roles.eks_node_candidates) > 0 ? tolist(data.aws_iam_roles.eks_node_candidates[0].names) : []
  resolved_eks_cluster_role_name = var.eks_cluster_role_name != "" ? var.eks_cluster_role_name : length(local.eks_cluster_role_names) > 0 ? local.eks_cluster_role_names[0] : ""
}

data "aws_iam_role" "eks_cluster" {
  count = local.resolved_eks_cluster_role_name != "" ? 1 : 0
  name  = local.resolved_eks_cluster_role_name
}

# ============================================
# EKS CLUSTER
# ============================================

resource "aws_eks_cluster" "main" {
  name     = "despachos-cluster"
  role_arn = local.eks_cluster_role_arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id,
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
  }

  tags = { Name = "despachos-cluster" }
}

# ============================================
# IAM ROLES FOR EKS NODE GROUP
# ============================================

data "aws_iam_roles" "eks_node_candidates" {
  count      = var.eks_nodes_role_name == "" ? 1 : 0
  name_regex = ".*${var.eks_node_tag_filter}.*"
}

locals {
  resolved_eks_nodes_role_name = var.eks_nodes_role_name != "" ? var.eks_nodes_role_name : length(local.eks_node_role_names) > 0 ? local.eks_node_role_names[0] : ""
  eks_cluster_role_arn         = try(data.aws_iam_role.eks_cluster[0].arn, null)
  eks_nodes_role_arn           = try(data.aws_iam_role.eks_nodes[0].arn, null)
}

data "aws_iam_role" "eks_nodes" {
  count = local.resolved_eks_nodes_role_name != "" ? 1 : 0
  name  = local.resolved_eks_nodes_role_name
}

# ============================================
# EKS NODE GROUP
# ============================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "despachos-nodes"
  node_role_arn   = local.eks_nodes_role_arn
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  tags = { Name = "despachos-nodes" }
}

# ============================================
# APPLICATION LOAD BALANCER (ALB)
# ============================================

resource "aws_lb" "main" {
  name               = "despacho-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_public.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = { Name = "despacho-alb" }
}

# Target Group - Frontend
resource "aws_lb_target_group" "frontend" {
  name        = "despacho-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = { Name = "despacho-frontend-tg" }
}

# Target Group - Backend Ventas
resource "aws_lb_target_group" "backend_ventas" {
  name        = "despacho-backend-ventas-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }

  tags = { Name = "despacho-backend-ventas-tg" }
}

# Target Group - Backend Despachos
resource "aws_lb_target_group" "backend_despacho" {
  name        = "despacho-backend-despacho-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
  }

  tags = { Name = "despacho-backend-despacho-tg" }
}

# ALB Listener - HTTP
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ALB Listener Rule - /api/ventas → Backend Ventas
resource "aws_lb_listener_rule" "backend_ventas" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_ventas.arn
  }

  condition {
    path_pattern {
      values = ["/api/ventas/*"]
    }
  }
}

# ALB Listener Rule - /api/despachos → Backend Despachos
resource "aws_lb_listener_rule" "backend_despacho" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_despacho.arn
  }

  condition {
    path_pattern {
      values = ["/api/despachos/*"]
    }
  }
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "IDs de los subnets públicos"
  value = {
    public_1 = aws_subnet.public_1.id
    public_2 = aws_subnet.public_2.id
  }
}

output "private_subnets" {
  description = "IDs de los subnets privados"
  value = {
    private_1 = aws_subnet.private_1.id
    private_2 = aws_subnet.private_2.id
  }
}

output "ecr_repositories" {
  description = "URLs de los repositorios ECR"
  value = {
    backend_ventas   = aws_ecr_repository.backend_ventas_repo.repository_url
    backend_despacho = aws_ecr_repository.backend_despacho_repo.repository_url
    frontend         = aws_ecr_repository.frontend_despacho_repo.repository_url
  }
}

output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_arn" {
  description = "ARN del cluster EKS"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_certificate" {
  description = "Certificado de autoridad del cluster EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "nat_gateway_ip" {
  description = "IP pública del NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "security_groups" {
  description = "IDs de los Security Groups"
  value = {
    alb_public = aws_security_group.alb_public.id
    eks_nodes  = aws_security_group.eks_nodes.id
    database   = aws_security_group.database.id
  }
}