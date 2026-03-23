terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "togglemaster-fase3-tfstate-001"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}