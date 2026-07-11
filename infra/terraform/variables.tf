variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS"
  type        = string
  default     = "default"
}

variable "aws_access_key_id" {
  description = "Access key ID de AWS"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "Secret access key de AWS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_session_token" {
  description = "Session token de AWS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "innovatech"
}

variable "eks_cluster_role_name" {
  description = "Nombre del rol de EKS cluster"
  type        = string
  default     = ""
}

variable "eks_nodes_role_name" {
  description = "Nombre del rol de nodos de EKS"
  type        = string
  default     = ""
}

variable "eks_role_tag_filter" {
  description = "Filtro de tags para rol de EKS cluster"
  type        = string
  default     = "LabEksClusterRole"
}

variable "eks_node_tag_filter" {
  description = "Filtro de tags para rol de nodos de EKS"
  type        = string
  default     = "LabEksNodeRole"
}

variable "rds_db_name" {
  description = "Nombre de la base de datos RDS"
  type        = string
  default     = "despachos_db"
}

variable "rds_db_username" {
  description = "Usuario de la base de datos RDS"
  type        = string
  default     = "admin"
}

variable "rds_db_password" {
  description = "Contraseña de la base de datos RDS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento asignado para RDS"
  type        = number
  default     = 20
}

variable "rds_backup_retention_days" {
  description = "Días de retención de backups de RDS"
  type        = number
  default     = 30
}

variable "rds_multi_az" {
  description = "Habilitar RDS Multi-AZ"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Correo para alertas"
  type        = string
  default     = ""
}