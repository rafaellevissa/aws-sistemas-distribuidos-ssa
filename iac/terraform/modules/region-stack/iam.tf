# ============================================================================
# 5. IAM ROLES & POLICIES + LOG GROUP
# Dando autonomia a maquina para ler segredos e imagens sem senhas hardcoded.
# ============================================================================
resource "aws_cloudwatch_log_group" "app" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name_prefix        = "${var.environment_name}-ec2-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_full" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Permissao para ler o secret do banco. Na regiao primaria referencia o secret local;
# nas secundarias referencia o secret da regiao primaria pelo nome (ARN cross-region).
data "aws_iam_policy_document" "read_secrets" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.create_database
      ? aws_secretsmanager_secret.db[0].arn
      : "arn:aws:secretsmanager:${local.db_secret_region}:${local.account_id}:secret:${local.db_secret_name}*"
    ]
  }
}

resource "aws_iam_role_policy" "read_secrets" {
  name_prefix = "read-secrets-"
  role        = aws_iam_role.ec2.id
  policy      = data.aws_iam_policy_document.read_secrets.json
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.environment_name}-ec2-"
  role        = aws_iam_role.ec2.name

  lifecycle {
    create_before_destroy = true
  }
}
