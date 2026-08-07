terraform {
  required_version = ">= 1.8.0, < 2.0.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4, < 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
