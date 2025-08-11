terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# Optional backend (commented). If you have a shared S3 bucket + DynamoDB for lock, uncomment and fill values.
# terraform {
#   backend "s3" {
#     bucket = "YOUR_TF_STATE_BUCKET"
#     key    = "bsg-devops/terraform.tfstate"
#     region = "af-south-1"
#   }
# }
