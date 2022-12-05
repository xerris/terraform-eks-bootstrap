data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_eip" "nat" {
  count = var.count_eip_nat

  vpc = true
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  create_vpc      = var.create_vpc
  name            = "${var.vpc_name}-${var.env}"
  cidr            = var.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = var.enable_natgateway
  single_nat_gateway   = true
  reuse_nat_ips        = true # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids  = aws_eip.nat.*.id
  enable_vpn_gateway   = var.enable_vpngateway
  enable_dns_hostnames = true

  tags = {
    Owner       = var.owner_tag
    Project     = var.project
    Environment = var.env
    Terraform   = true
  }
}
/*
resource "random_integer" "id-db" {
  min     = 1
  max     = 50
  keepers = {
    listener_arn = "${var.rds_cluster_name}-${var.env}"
  }
}

resource "random_password" "password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "aws_rds_cluster" "rds_cluster" {
  count = var.create_db ? 1 : 0
  depends_on = [ module.vpc ]
  cluster_identifier      = "${var.rds_cluster_name}-${var.env}-${random_integer.id-db.result}"
  engine                  = var.rds_engine
  engine_version          = var.engine_version
  availability_zones      = data.aws_availability_zones.available.names
  database_name           = var.db_name
  master_username         = 
  
  master_password         = random_password.password.result
  backup_retention_period = var.db_backup_retention
  preferred_backup_window = var.db_backup_window
  skip_final_snapshot = true
  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }
}

*/
output "vpc_data" {
  value = {
    id                = local.vpc_id
    priv_subnet_ids   = local.subnet_ids
    public_subnet_ids = local.public_subnet_ids
    #rds_endpoint = aws_rds_cluster.rds_cluster.endpoint
    #rds_master_user = var.db_master_user
    #rds_master_password = random_password.password.result
  }
  sensitive = true
}