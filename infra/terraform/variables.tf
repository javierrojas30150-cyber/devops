variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "innovatech"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS"
  type        = string
  default     = "innovatech-eks"
}