# ============================================================================
# 8. LAUNCH TEMPLATE & AUTO SCALING GROUP (Imutabilidade)
# Provisionamento agil onde o servidor nasce, instala tudo e morre sem pena.
# ============================================================================
locals {
  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    db_secret_name   = local.db_secret_name
    db_secret_region = local.db_secret_region
    db_host          = local.db_host
    db_name          = var.db_name
    region           = local.region
    account_id       = local.account_id
    image_uri        = local.image_uri
    s3_bucket_name   = local.s3_bucket_name
    s3_bucket_region = local.s3_bucket_region
    log_group_name   = var.log_group_name
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment_name}-"
  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.environment_name}-api"
    })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.environment_name}-"
  min_size            = var.asg_min_size # Conceito Tanenbaum: redundancia minima de hardware
  max_size            = var.asg_max_size
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # Rolling instance refresh: usado pelo pipeline para redeployar nova imagem.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 150
      instance_warmup        = 180
    }
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
