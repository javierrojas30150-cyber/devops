terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ============================================
# NO CREAMOS VPC, SUBNETS, NI EKS
# Usamos recursos existentes (que probablemente no puedas leer)
# ============================================

# Intentamos obtener la VPC por defecto (fallará por permisos)
data "aws_vpc" "default" {
  default = true
}

# Obtenemos subnets de la VPC por defecto
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Obtenemos el clúster EKS existente (fallará si no existe o no tienes permisos)
# data "aws_eks_cluster" "existing" {
#   name = "despachos-cluster"
# }

# Obtenemos el rol de nodos existente
data "aws_iam_role" "node_role" {
  name = "LabRole"
}

# ============================================
# SOLO CREAMOS ECR REPOSITORIES (si tienes permisos)
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
# OUTPUTS
# ============================================

output "ecr_repositories" {
  value = {
    ventas    = aws_ecr_repository.backend_ventas_repo.repository_url
    despachos = aws_ecr_repository.backend_despacho_repo.repository_url
    frontend  = aws_ecr_repository.frontend_despacho_repo.repository_url
  }
}