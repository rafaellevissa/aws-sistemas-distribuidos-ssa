# Provider da regiao primaria (us-east-1): hospeda RDS, Secret, S3 e o dashboard.
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = {
      Project   = "aws-sistemas-distribuidos-ssa"
      ManagedBy = "terraform"
    }
  }
}

# Provider da regiao secundaria (eu-central-1).
provider "aws" {
  region = "eu-central-1"
  alias  = "eu_central_1"

  default_tags {
    tags = {
      Project   = "aws-sistemas-distribuidos-ssa"
      ManagedBy = "terraform"
    }
  }
}
