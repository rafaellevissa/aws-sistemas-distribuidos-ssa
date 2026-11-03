variable "environment_name" {
  type        = string
  description = "Prefixo de nomeacao do ambiente."
  default     = "caos-demo-unifan"
}

variable "ecr_repository_name" {
  type        = string
  description = "Nome do repositorio ECR com a imagem Docker da API."
  default     = "unifan-sistemas-distribuidos-terraform"
}

variable "image_tag" {
  type        = string
  description = "Tag da imagem no ECR que as instancias EC2 devem puxar."
  default     = "latest"
}

variable "instance_type" {
  type        = string
  description = "Tipo das instancias EC2 do ASG."
  default     = "t2.micro"
}

variable "asg_min_size" {
  type        = number
  description = "Numero minimo de instancias no ASG."
  default     = 2
}

variable "asg_max_size" {
  type        = number
  description = "Numero maximo de instancias no ASG."
  default     = 5
}

variable "log_group_name" {
  type        = string
  description = "Nome do CloudWatch Log Group da API."
  default     = "/unifan/caos-demo-api"
}

variable "log_retention_days" {
  type        = number
  description = "Retencao dos logs da API em dias."
  default     = 1
}

variable "db_instance_class" {
  type        = string
  description = "Classe da instancia RDS."
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Armazenamento alocado para o RDS em GB."
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Nome do schema/banco MySQL utilizado pela API."
  default     = "aula_pratica_db"
}

variable "db_multi_az" {
  type        = bool
  description = "Habilita Multi-AZ no RDS (HA do banco)."
  default     = false
}

variable "s3_bucket_name" {
  type        = string
  description = "Nome do bucket S3 de imagens. Se vazio, usa aula-pratica-imagens-<account_id>."
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "Dominio principal hospedado no Route53 (hosted zone ja existente)."
  default     = "rafaellevi.com.br"
}

variable "subdomain_name" {
  type        = string
  description = "Subdominio da aplicacao."
  default     = "unifan-sistemas-distribuidos"
}
