terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

# ============================================================================
# Dados de contexto e resolucao de valores derivados
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Busca automatica da ultima AMI do Ubuntu 22.04 na regiao (SSM Parameter oficial Canonical)
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

locals {
  account_id       = data.aws_caller_identity.current.account_id
  region           = data.aws_region.current.region
  s3_bucket_name   = var.s3_bucket_name != "" ? var.s3_bucket_name : "aula-pratica-imagens-${local.account_id}"
  s3_bucket_region = var.s3_bucket_region != "" ? var.s3_bucket_region : local.region
  image_uri        = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.ecr_repository_name}:${var.image_tag}"

  # Na regiao primaria o banco e criado localmente; nas secundarias vem por variavel.
  db_host          = var.create_database ? aws_db_instance.this[0].address : var.db_host
  db_secret_name   = var.create_database ? aws_secretsmanager_secret.db[0].name : var.db_secret_name
  db_secret_region = var.create_database ? local.region : var.db_secret_region
  db_secret_arn    = var.create_database ? aws_secretsmanager_secret.db[0].arn : ""

  common_tags = merge({
    Environment = var.environment_name
    ManagedBy   = "terraform"
    Project     = "aws-sistemas-distribuidos-ssa"
  }, var.tags)
}
