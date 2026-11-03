output "load_balancer_dns" {
  description = "DNS publico do ALB"
  value       = aws_lb.app.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID do ALB (para alias no Route53)"
  value       = aws_lb.app.zone_id
}

output "load_balancer_full_name" {
  description = "Nome completo do ALB (dimensao LoadBalancer no CloudWatch)"
  value       = aws_lb.app.arn_suffix
}

output "target_group_full_name" {
  description = "Nome completo do Target Group (dimensao TargetGroup no CloudWatch)"
  value       = aws_lb_target_group.app.arn_suffix
}

output "autoscaling_group_name" {
  description = "Nome do ASG que registra as instancias no Target Group"
  value       = aws_autoscaling_group.app.name
}

output "app_log_group_name" {
  description = "Log group da API (um log stream por instancia)"
  value       = aws_cloudwatch_log_group.app.name
}

output "ecr_repository_url" {
  description = "URL do repositorio ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Nome do repositorio ECR"
  value       = aws_ecr_repository.app.name
}

# ---- Outputs do banco (so preenchidos na regiao primaria) ----
output "db_host" {
  description = "Endpoint do RDS (vazio em regioes secundarias)"
  value       = var.create_database ? aws_db_instance.this[0].address : ""
}

output "db_secret_name" {
  description = "Nome do secret do banco (vazio em regioes secundarias)"
  value       = var.create_database ? aws_secretsmanager_secret.db[0].name : ""
}

output "db_secret_arn" {
  description = "ARN do secret do banco (vazio em regioes secundarias)"
  value       = var.create_database ? aws_secretsmanager_secret.db[0].arn : ""
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS (usado pelo workflow de schema para liberar acesso temporario)"
  value       = var.create_database ? aws_security_group.rds[0].id : ""
}

# ---- S3 ----
output "s3_bucket_name" {
  description = "Nome do bucket S3 de imagens"
  value       = local.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3 (vazio se criado em outra regiao)"
  value       = var.create_s3_bucket ? aws_s3_bucket.app[0].arn : ""
}
