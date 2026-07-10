terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8081
    to_port   = 8081
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "frontend" {
  name         = "${var.project_name}-frontend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ventas_backend" {
  name         = "${var.project_name}-ventas-backend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "despacho_backend" {
  name         = "${var.project_name}-despacho-backend"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_eks_cluster" "eks" {
  name     = "${var.project_name}-cluster"
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet_1.id,
      aws_subnet.subnet_2.id
    ]
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn   = data.aws_iam_role.labrole.arn

  subnet_ids = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  instance_types = ["t3.small"]

  capacity_type = "ON_DEMAND"
}

resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "ebs-gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }
}

resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/eks/${var.project_name}/logs"
  retention_in_days = 3
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "frontend_repository" {
  value = aws_ecr_repository.frontend.repository_url
}

output "ventas_repository" {
  value = aws_ecr_repository.ventas_backend.repository_url
}

output "despacho_repository" {
  value = aws_ecr_repository.despacho_backend.repository_url
}