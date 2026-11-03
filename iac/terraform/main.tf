# ============================================================================
# RAIZ: orquestra as duas regioes + Route53 (latency routing) + dashboard.
# Um unico `terraform apply` provisiona toda a arquitetura multi-regiao.
# ============================================================================

# ----------------------------------------------------------------------------
# Regiao PRIMARIA (us-east-1): cria RDS, Secret e o bucket S3 (global).
# ----------------------------------------------------------------------------
module "us_east_1" {
  source = "./modules/region-stack"

  providers = {
    aws = aws.us_east_1
  }

  environment_name    = var.environment_name
  region              = "us-east-1"
  ecr_repository_name = var.ecr_repository_name
  image_tag           = var.image_tag
  instance_type       = var.instance_type
  asg_min_size        = var.asg_min_size
  asg_max_size        = var.asg_max_size
  log_group_name      = var.log_group_name
  log_retention_days  = var.log_retention_days

  # Regiao primaria: cria banco + Secret + bucket S3.
  create_database      = true
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_multi_az          = var.db_multi_az

  create_s3_bucket = true
  s3_bucket_name   = var.s3_bucket_name
  s3_bucket_region = "us-east-1"
}

# ----------------------------------------------------------------------------
# Regiao SECUNDARIA (eu-central-1): consome o banco/secret/S3 da primaria.
# ----------------------------------------------------------------------------
module "eu_central_1" {
  source = "./modules/region-stack"

  providers = {
    aws = aws.eu_central_1
  }

  environment_name    = var.environment_name
  region              = "eu-central-1"
  ecr_repository_name = var.ecr_repository_name
  image_tag           = var.image_tag
  instance_type       = var.instance_type
  asg_min_size        = var.asg_min_size
  asg_max_size        = var.asg_max_size
  log_group_name      = var.log_group_name
  log_retention_days  = var.log_retention_days

  # Regiao secundaria: NAO cria banco/S3; consome os da primaria.
  create_database  = false
  create_s3_bucket = false
  db_host          = module.us_east_1.db_host
  db_secret_name   = module.us_east_1.db_secret_name
  db_secret_region = "us-east-1"
  s3_bucket_name   = module.us_east_1.s3_bucket_name
  s3_bucket_region = "us-east-1"
}

# ----------------------------------------------------------------------------
# ROUTE 53 (DNS e transparencia de localizacao) - Latency Routing
# Assume que a hosted zone de var.domain_name ja existe na conta.
# ----------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  provider     = aws.us_east_1
  name         = "${var.domain_name}."
  private_zone = false
}

locals {
  regions = {
    "us-east-1" = {
      dns_name = module.us_east_1.load_balancer_dns
      zone_id  = module.us_east_1.load_balancer_zone_id
    }
    "eu-central-1" = {
      dns_name = module.eu_central_1.load_balancer_dns
      zone_id  = module.eu_central_1.load_balancer_zone_id
    }
  }
}

resource "aws_route53_record" "app" {
  provider = aws.us_east_1
  for_each = local.regions

  zone_id        = data.aws_route53_zone.main.zone_id
  name           = "${var.subdomain_name}.${var.domain_name}"
  type           = "A"
  set_identifier = "${each.key}-region"

  latency_routing_policy {
    region = each.key
  }

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = true
  }
}

# ----------------------------------------------------------------------------
# DASHBOARD (CloudWatch multi-regiao) - hospedado em us-east-1
# ----------------------------------------------------------------------------
module "dashboard" {
  source = "./modules/dashboard"

  providers = {
    aws = aws.us_east_1
  }

  dashboard_name = "${var.environment_name}-requests"
  log_group_name = var.log_group_name

  us_east_1_load_balancer_full_name = module.us_east_1.load_balancer_full_name
  us_east_1_target_group_full_name  = module.us_east_1.target_group_full_name
  us_east_1_autoscaling_group_name  = module.us_east_1.autoscaling_group_name

  eu_central_1_load_balancer_full_name = module.eu_central_1.load_balancer_full_name
  eu_central_1_target_group_full_name  = module.eu_central_1.target_group_full_name
  eu_central_1_autoscaling_group_name  = module.eu_central_1.autoscaling_group_name
}
