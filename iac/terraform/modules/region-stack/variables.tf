variable "environment_name" {
  type        = string
  description = "Prefixo de nomeacao do ambiente (ex: caos-demo-unifan)."
  default     = "caos-demo-unifan"
}

variable "region" {
  type        = string
  description = "Regiao AWS onde a stack desta regiao sera provisionada."
}

variable "ecr_repository_name" {
  type        = string
  description = "Nome do repositorio ECR que guarda a imagem Docker da API."
  default     = "unifan-sistemas-distribuidos-terraform"
}

variable "image_tag" {
  type        = string
  description = "Tag da imagem no ECR que as instancias EC2 devem puxar."
  default     = "latest"
}

variable "instance_type" {
  type        = string
  description = "Tipo das instancias EC2 do Auto Scaling Group."
  default     = "t2.micro"
}

variable "asg_min_size" {
  type        = number
  description = "Numero minimo de instancias no ASG (redundancia minima de hardware)."
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

# ---- Banco de dados (apenas na regiao primaria) ----
variable "create_database" {
  type        = bool
  description = "Se true, cria RDS MySQL + Secret nesta regiao (regiao primaria). As demais regioes consomem o banco da primaria."
  default     = false
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
  description = "Habilita Multi-AZ no RDS (tolerancia a falhas do banco)."
  default     = false
}

# ---- Consumo do banco por regioes secundarias ----
variable "db_host" {
  type        = string
  description = "Endpoint do RDS criado na regiao primaria (usado por regioes secundarias)."
  default     = ""
}

variable "db_secret_name" {
  type        = string
  description = "Nome do Secret com as credenciais do banco criado na regiao primaria."
  default     = ""
}

variable "db_secret_region" {
  type        = string
  description = "Regiao onde o Secret do banco foi criado."
  default     = ""
}

# ---- S3 ----
variable "s3_bucket_name" {
  type        = string
  description = "Nome do bucket S3 de imagens. Se vazio, usa aula-pratica-imagens-<account_id>. Compartilhado globalmente, criado uma unica vez."
  default     = ""
}

variable "create_s3_bucket" {
  type        = bool
  description = "Se true, cria o bucket S3 de imagens nesta regiao (bucket e global, crie em apenas uma regiao)."
  default     = false
}

variable "s3_bucket_region" {
  type        = string
  description = "Regiao do bucket S3 de imagens (usada pela aplicacao na variavel AWS_S3_REGION)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags aplicadas aos recursos."
  default     = {}
}
