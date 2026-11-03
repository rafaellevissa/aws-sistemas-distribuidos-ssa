# ============================================================================
# 7. WAF (Web Application Firewall)
# Injetando seguranca na camada de aplicacao distribuida.
# ============================================================================
resource "aws_wafv2_web_acl" "app" {
  name        = "${var.environment_name}-web-acl"
  description = "WAF regional para o ALB da API"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "AppWebACL"
  }

  # Regra 1: AWS Managed Common Rule Set. A regra SizeRestrictions_BODY e
  # sobrescrita para Count para que a regra custom (prioridade 2) decida.
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
    }
  }

  # Regra 2: bloqueia corpos grandes, exceto em POST /upload (endpoint de upload de imagem).
  rule {
    name     = "BlockOversizedBodyOutsideUpload"
    priority = 2

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          label_match_statement {
            scope = "LABEL"
            key   = "awswaf:managed:aws:core-rule-set:SizeRestrictions_Body"
          }
        }
        statement {
          not_statement {
            statement {
              and_statement {
                statement {
                  regex_match_statement {
                    regex_string = "^/upload/?$"
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
                statement {
                  byte_match_statement {
                    search_string         = "POST"
                    positional_constraint = "EXACTLY"
                    field_to_match {
                      method {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockOversizedBodyOutsideUpload"
    }
  }

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "app" {
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.app.arn
}
