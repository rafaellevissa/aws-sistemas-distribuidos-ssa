variable "dashboard_name" {
  type        = string
  description = "Nome do dashboard do CloudWatch."
  default     = "caos-demo-unifan-requests"
}

variable "log_group_name" {
  type        = string
  description = "Nome do log group da API (compartilhado entre regioes)."
  default     = "/unifan/caos-demo-api"
}

variable "us_east_1_load_balancer_full_name" {
  type        = string
  description = "arn_suffix do ALB da regiao us-east-1 (app/<nome>/<id>)."
}

variable "us_east_1_target_group_full_name" {
  type        = string
  description = "arn_suffix do Target Group da regiao us-east-1 (targetgroup/<nome>/<id>)."
}

variable "us_east_1_autoscaling_group_name" {
  type        = string
  description = "Nome do ASG da regiao us-east-1."
}

variable "eu_central_1_load_balancer_full_name" {
  type        = string
  description = "arn_suffix do ALB da regiao eu-central-1 (app/<nome>/<id>)."
}

variable "eu_central_1_target_group_full_name" {
  type        = string
  description = "arn_suffix do Target Group da regiao eu-central-1 (targetgroup/<nome>/<id>)."
}

variable "eu_central_1_autoscaling_group_name" {
  type        = string
  description = "Nome do ASG da regiao eu-central-1."
}
