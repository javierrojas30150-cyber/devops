variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use; leave empty to use the default credential chain"
  type        = string
  default     = ""
}

variable "aws_shared_credentials_file" {
  description = "Optional path to the AWS shared credentials file"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_session_token" {
  description = "AWS Session Token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "eks_cluster_role_name" {
  description = "IAM role name for EKS cluster"
  type        = string
  default     = ""
}

variable "eks_nodes_role_name" {
  description = "IAM role name for EKS nodes"
  type        = string
  default     = ""
}

variable "eks_role_tag_filter" {
  description = "Tag keyword to filter EKS cluster roles dynamically"
  type        = string
  default     = "LabEksClusterRole"
}

variable "eks_node_tag_filter" {
  description = "Tag keyword to filter EKS node roles dynamically"
  type        = string
  default     = "LabEksNodeRole"
}

# ============================================
# RDS Variables
# ============================================

variable "rds_db_name" {
  description = "Base de datos inicial de RDS"
  type        = string
  default     = "despachos_db"
}

variable "rds_db_username" {
  description = "Usuario root de RDS MySQL"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_db_password" {
  description = "Contraseña de RDS MySQL"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento asignado a RDS (GB)"
  type        = number
  default     = 20
}

variable "rds_backup_retention_days" {
  description = "Días de retención de backups"
  type        = number
  default     = 30
}

variable "rds_multi_az" {
  description = "Habilitar Multi-AZ para RDS"
  type        = bool
  default     = true
}

# ============================================
# Alertas y Monitoreo
# ============================================

variable "alert_email" {
  description = "Email para recibir alertas"
  type        = string
  default     = "alerts@example.com"
}