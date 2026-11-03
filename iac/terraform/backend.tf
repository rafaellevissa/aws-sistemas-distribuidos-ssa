terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }

  # Backend de state em S3 (sem DynamoDB lock, conforme decidido).
  # Os valores concretos ficam em backend.hcl (ou passados via -backend-config).
  # Inicialize com:  terraform init -backend-config=backend.hcl
  backend "s3" {
    key    = "aws-sistemas-distribuidos-ssa/terraform.tfstate"
    region = "us-east-1"
  }
}
