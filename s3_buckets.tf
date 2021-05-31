data "aws_kms_key" "aws_s3_key" {
  key_id = "alias/aws/s3"
}

module "s3_cluster_logs" {
  source = "git@github.com:xerris/aws-modules.git//s3"

  bucket        = "k8-logs-${var.env}"
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.aws_kms_key.aws_s3_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }
}

module "path_cluster_logs" {
  source = "git@github.com:xerris/aws-modules.git//s3"

  bucket        = "cluster-logs-${var.env}"
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.aws_kms_key.aws_s3_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }
}

module "path_node_logs" {
  source = "git@github.com:xerris/aws-modules.git//s3"

  bucket        = "node-logs-${var.env}"
  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.aws_kms_key.aws_s3_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }
}