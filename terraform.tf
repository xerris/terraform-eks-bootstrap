terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.67.0"
    }
  }
}

provider "aws" {
  region  = var.region
  #assume_role {
  #  role_arn     = "arn:aws:iam::${var.account_id}:role/aldo-jenkins"
  #  session_name = "${var.env}-omni-dataapps"
  #}
}