data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_eip" "nat" {
  count = var.count_eip_nat

  vpc = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  create_vpc           = var.create_vpc
  name = var.vpc_name
  cidr = var.vpc_subnet
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_natgateway
  single_nat_gateway  = true
  reuse_nat_ips       = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat.*.id
  enable_vpn_gateway = var.enable_vpngateway
  enable_dns_hostnames = true

  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }
}

output "vpc_data" {
    value ={
        id = module.vpc.vpc_id
        subnet_ids = module.vpc.private_subnets
    }
}