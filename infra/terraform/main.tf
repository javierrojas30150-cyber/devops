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

locals {
  project_name = var.project_name
  cluster_name = var.cluster_name
}

# ==========================
# IAM
# ==========================

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

# ==========================
# NETWORK
# ==========================

resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.project_name}-vpc"
  }
}

resource "aws_subnet" "eks_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                       = "${local.project_name}-subnet-1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                       = "${local.project_name}-subnet-2"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${local.project_name}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.project_name}-rt"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

# ==========================
# SECURITY GROUP
# ==========================

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${local.project_name}-eks-sg"
  description = "Security Group para EKS"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description = "Kubernetes API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================
# ECR
# ==========================

resource "aws_ecr_repository" "frontend_repo" {
  name         = "${local.project_name}-frontend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ventas_repo" {
  name         = "${local.project_name}-ventas"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "despachos_repo" {
  name         = "${local.project_name}-despachos"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ==========================
# EKS
# ==========================

resource "aws_eks_cluster" "eks" {
  name     = local.cluster_name
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids              = [
      aws_subnet.eks_subnet_1.id,
      aws_subnet.eks_subnet_2.id
    ]

    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = {
    Name = local.cluster_name
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${local.project_name}-workers"
  node_role_arn   = data.aws_iam_role.labrole.arn

  subnet_ids = [
    aws_subnet.eks_subnet_1.id,
    aws_subnet.eks_subnet_2.id
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
}

# ==========================
# OUTPUTS
# ==========================

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend_repo.repository_url
}

output "ventas_ecr_url" {
  value = aws_ecr_repository.ventas_repo.repository_url
}

output "despachos_ecr_url" {
  value = aws_ecr_repository.despachos_repo.repository_url
}

output "connect_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks.name}"
}