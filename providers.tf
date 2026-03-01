terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Production: use remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ai-payments/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project            = "ai-payments-reference-architecture"
      ManagedBy          = "Terraform"
      Environment        = var.environment
      DataClassification = "Confidential"
      Owner              = var.owner_tag
      CostCenter         = var.cost_center
    }
  }
}
