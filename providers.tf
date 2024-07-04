terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }
}

#AWS provider
provider "aws" {
  region = var.aws_region
}