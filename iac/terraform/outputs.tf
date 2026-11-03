output "us_east_1_load_balancer_dns" {
  description = "DNS publico do ALB em us-east-1"
  value       = module.us_east_1.load_balancer_dns
}

output "eu_central_1_load_balancer_dns" {
  description = "DNS publico do ALB em eu-central-1"
  value       = module.eu_central_1.load_balancer_dns
}

output "app_domain" {
  description = "Dominio final acessivel pelo usuario"
  value       = "${var.subdomain_name}.${var.domain_name}"
}

output "ecr_repository_url_us_east_1" {
  description = "URL do repositorio ECR em us-east-1 (usado pelo pipeline de build)"
  value       = module.us_east_1.ecr_repository_url
}

output "db_host" {
  description = "Endpoint do RDS (regiao primaria)"
  value       = module.us_east_1.db_host
}

output "db_secret_name" {
  description = "Nome do secret do banco (regiao primaria)"
  value       = module.us_east_1.db_secret_name
}

output "rds_security_group_id" {
  description = "ID do SG do RDS (para liberar acesso temporario na aplicacao do schema)"
  value       = module.us_east_1.rds_security_group_id
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 de imagens"
  value       = module.us_east_1.s3_bucket_name
}

output "dashboard_url" {
  description = "URL do painel no CloudWatch"
  value       = module.dashboard.dashboard_url
}

# ---- Outputs por regiao para o dashboard/metricas ----
output "us_east_1_autoscaling_group_name" {
  value       = module.us_east_1.autoscaling_group_name
  description = "Nome do ASG em us-east-1"
}

output "eu_central_1_autoscaling_group_name" {
  value       = module.eu_central_1.autoscaling_group_name
  description = "Nome do ASG em eu-central-1"
}
