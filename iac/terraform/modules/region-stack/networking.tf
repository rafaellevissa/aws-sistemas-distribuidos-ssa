# ============================================================================
# 1. NETWORKING (VPC, Subnets, Internet Gateway)
# A base fisica da rede distribuida.
# ============================================================================
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-igw"
  })
}

# Subnets publicas em AZs distintas para o ALB e o ASG (multi-AZ)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-public-1"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-public-2"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# 2. SECURITY GROUPS
# Regras de comunicacao entre os processos distribuidos.
# ============================================================================
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment_name}-alb-"
  description = "Permite trafego HTTP mundial para o Load Balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP de qualquer origem"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "${var.environment_name}-ec2-"
  description = "Permite trafego HTTP para as instancias EC2 na porta 80 e SSH (didatico)"
  vpc_id      = aws_vpc.this.id

  # Didatico: porta 80 aberta. Em producao, restringir ao SG do ALB.
  ingress {
    description = "HTTP (didatico - em prod restringir ao SG do ALB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (apenas didatico - em prod restringir IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_name}-ec2-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS SG apenas na regiao primaria (onde o banco existe)
resource "aws_security_group" "rds" {
  count = var.create_database ? 1 : 0

  name_prefix = "${var.environment_name}-rds-"
  description = "Permite acesso ao MySQL na porta 3306"
  vpc_id      = aws_vpc.this.id

  # Didatico: aberto para permitir acesso multi-regiao e aplicacao do schema via CI.
  ingress {
    description = "MySQL (didatico)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_name}-rds-sg" })

  lifecycle {
    create_before_destroy = true
  }
}
