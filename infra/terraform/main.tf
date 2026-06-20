terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
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
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
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
# SECURITY GROUP PARA ALB - PÚBLICO SIN RESTRICCIONES
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

  # Permitir HTTPS desde cualquier dirección (por si acaso)
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
# ECR REPOSITORIES
# ============================================

resource "aws_ecr_repository" "backend_despacho_repo" {
  name                 = "backend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
  tags = { Project = "innovatech" }
}

resource "aws_ecr_repository" "backend_ventas_repo" {
  name                 = "backend-ventas"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
  tags = { Project = "innovatech" }
}

resource "aws_ecr_repository" "frontend_despacho_repo" {
  name                 = "frontend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
  tags = { Project = "innovatech" }
}

# ============================================
# IAM ROLES FOR EKS CLUSTER (Using existing Lab Roles)
# ============================================

data "aws_iam_role" "eks_cluster" {
  name = "c216581a5470593l15483883t1w548946-LabEksClusterRole-ZuHNGEMyAN1t"
}

# ============================================
# EKS CLUSTER
# ============================================

resource "aws_eks_cluster" "main" {
  name     = "despachos-cluster"
  role_arn = data.aws_iam_role.eks_cluster.arn
  
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
# IAM ROLES FOR EKS NODE GROUP (Using existing Lab Roles)
# ============================================

data "aws_iam_role" "eks_nodes" {
  name = "c216581a5470593l15483883t1w548946983-LabEksNodeRole-vNNCzcILB6sW"
}

# ============================================
# EKS NODE GROUP
# ============================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "despachos-nodes"
  node_role_arn   = data.aws_iam_role.eks_nodes.arn
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
# OUTPUTS
# ============================================

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

output "nat_gateway_ip" {
  description = "IP pública del NAT Gateway"
  value       = aws_eip.nat.public_ip
}