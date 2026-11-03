# ============================================================================
# 3. SECRETS MANAGER & RDS (MySQL)  -- apenas na regiao primaria
# Tolerancia a falhas nos dados e seguranca de credenciais.
# ============================================================================
resource "random_password" "db" {
  count = var.create_database ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  count = var.create_database ? 1 : 0

  name        = "${var.environment_name}-db-credentials"
  description = "Credenciais do MySQL geradas dinamicamente"

  # Didatico: permite recriar a stack sem esperar a janela de recovery.
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db" {
  count = var.create_database ? 1 : 0

  secret_id = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db[0].result
  })
}

resource "aws_db_subnet_group" "this" {
  count = var.create_database ? 1 : 0

  name        = "${var.environment_name}-db-subnets"
  description = "Subnets para o banco de dados"
  subnet_ids  = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = local.common_tags
}

resource "aws_db_instance" "this" {
  count = var.create_database ? 1 : 0

  identifier                  = "${var.environment_name}-mysql"
  engine                      = "mysql"
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  backup_retention_period     = 3
  auto_minor_version_upgrade  = true
  username                    = jsondecode(aws_secretsmanager_secret_version.db[0].secret_string)["username"]
  password                    = jsondecode(aws_secretsmanager_secret_version.db[0].secret_string)["password"]
  db_subnet_group_name        = aws_db_subnet_group.this[0].name
  vpc_security_group_ids      = [aws_security_group.rds[0].id]
  multi_az                    = var.db_multi_az # true para replicar e garantir HA (tolerancia a falhas do BD)
  publicly_accessible         = true            # Didatico para a aula
  skip_final_snapshot         = true            # Didatico: evita snapshot final no destroy
  deletion_protection         = false
  allow_major_version_upgrade = false

  tags = local.common_tags
}

# ============================================================================
# 4. ECR (Elastic Container Registry)
# Repositorio de imagens Docker imutaveis.
# ============================================================================
resource "aws_ecr_repository" "app" {
  name         = var.ecr_repository_name
  force_delete = true # equivalente ao EmptyOnDelete do CloudFormation

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

# ============================================================================
# 4b. S3 (armazenamento de objetos / upload de imagens)
# Criado em apenas uma regiao (bucket e um recurso global).
# force_destroy = true substitui a Lambda custom resource que esvaziava o bucket.
# ============================================================================
resource "aws_s3_bucket" "app" {
  count = var.create_s3_bucket ? 1 : 0

  bucket        = local.s3_bucket_name
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "app" {
  count = var.create_s3_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.app[0].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
