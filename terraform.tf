terraform {
  backend "s3" {}
}

provider "aws" {
  region  = var.region
  #assume_role {
  #  role_arn     = "arn:aws:iam::${var.account_id}:role/aldo-jenkins"
  #  session_name = "${var.env}-omni-dataapps"
  #}
}