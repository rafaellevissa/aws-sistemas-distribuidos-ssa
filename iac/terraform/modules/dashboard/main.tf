terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

data "aws_region" "current" {}

# Dashboard multi-regiao: requests por ALB, CPU por ASG e requests por instancia (via logs).
# CPU e uma metrica de EC2 agregada por AutoScalingGroupName (equivale a CPU do Target Group,
# ja que cada ASG registra suas instancias em um unico TG).
resource "aws_cloudwatch_dashboard" "requests" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Requests - Load Balancer us-east-1"
          region  = "us-east-1"
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.us_east_1_load_balancer_full_name, { label = "Requests" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Requests - Load Balancer eu-central-1"
          region  = "eu-central-1"
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.eu_central_1_load_balancer_full_name, { label = "Requests" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "CPU Utilization - ${var.us_east_1_target_group_full_name} (us-east-1)"
          region  = "us-east-1"
          view    = "timeSeries"
          stacked = false
          period  = 300
          yAxis   = { left = { min = 0, max = 100 } }
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.us_east_1_autoscaling_group_name, { stat = "Average", label = "Media" }],
            ["...", { stat = "Maximum", label = "Maximo" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "CPU Utilization - ${var.eu_central_1_target_group_full_name} (eu-central-1)"
          region  = "eu-central-1"
          view    = "timeSeries"
          stacked = false
          period  = 300
          yAxis   = { left = { min = 0, max = 100 } }
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.eu_central_1_autoscaling_group_name, { stat = "Average", label = "Media" }],
            ["...", { stat = "Maximum", label = "Maximo" }]
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "Requests por instancia (us-east-1)"
          region  = "us-east-1"
          view    = "timeSeries"
          stacked = false
          query   = "SOURCE '${var.log_group_name}' | filter type = 'request' and userAgent not like /ELB-HealthChecker/ | stats count(*) as requests by bin(1m), @logStream"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "Requests por instancia (eu-central-1)"
          region  = "eu-central-1"
          view    = "timeSeries"
          stacked = false
          query   = "SOURCE '${var.log_group_name}' | filter type = 'request' and userAgent not like /ELB-HealthChecker/ | stats count(*) as requests by bin(1m), @logStream"
        }
      }
    ]
  })
}

output "dashboard_url" {
  description = "URL do painel no console do CloudWatch"
  value       = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards/dashboard/${var.dashboard_name}"
}
