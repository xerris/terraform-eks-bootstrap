data "aws_eks_cluster" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

data "aws_ami" "amazon-linux-2-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    #    client_key             = tls_private_key.this.private_key_pem
    host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}
provider "http" {
  # Configuration options
}


locals {
  depends_on        = [module.vpc]
  vpc_id            = var.create_vpc ? module.vpc.vpc_id : var.vpc_id
  subnet_ids        = var.create_vpc ? module.vpc.private_subnets : var.private_subnets_ids
  public_subnet_ids = var.create_vpc ? module.vpc.public_subnets : var.public_subnets_ids
  map_role = [
    {
      rolearn  = aws_iam_role.eks-default-role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
      username = "AWSServiceRoleForAmazonEKS"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/project_eks_cluster-dev-K8sFullAdmin"
      username = "project_eks_cluster-dev-K8sFullAdmin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/project_eks_cluster-dev-K8sClusterAdmin"
      username = "adminuser:{{SessionName}}"
      groups   = ["ad-cluster-admins"]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/project_eks_cluster-dev-K8sDeveloper"
      username = "devuser:{{SessionName}}"
      groups   = ["ad-cluster-devs"]
    } #,
    #{
    #  rolearn  = var.eks_master_role
    #  username = "AWSReservedSSO_AWSAdministratorAccess_c87e108deaf1b7ca/andres.duran@xerris.com"
    #  groups   = ["system:masters"]
    #}
  ]
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion_key_pair" {

  key_name   = "${var.eks_cluster_name}-${var.env}-key-pair"
  public_key = tls_private_key.this.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

resource "aws_security_group" "bastion" {
  name        = "bastion-security-group"
  description = "Allow SSH traffic"
  vpc_id      = local.vpc_id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner       = var.owner_tag
    Project     = var.project
    Environment = var.env
    Terraform   = true
  }
}


module "ec2_cluster" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "3.3.0"
  name                   = "bastion-${var.env}"
  count                  = var.create_bastion
  ami                    = data.aws_ami.amazon-linux-2-ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.bastion_key_pair.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = local.public_subnet_ids[0]
  tags = {
    Owner       = var.owner_tag
    Project     = var.project
    Environment = var.env
    Terraform   = true
  }
}

module "project_eks_cluster" {
  depends_on = [
    module.vpc,
    aws_iam_group_policy_attachment.K8sClusterAdmin-group-policy-attach,
    aws_iam_group_policy_attachment.K8sFullAdmin-group-policy-attach,
    aws_iam_group_policy_attachment.K8sDeveloper-group-policy-attach
  ]
  source                                         = "terraform-aws-modules/eks/aws"
  version                                        = "17.24.0"
  cluster_enabled_log_types                      = ["api", "audit", "authenticator", "scheduler", "controllerManager"]
  cluster_name                                   = "${var.eks_cluster_name}-${var.env}"
  cluster_version                                = var.eks_cluster_version
  subnets                                        = local.subnet_ids
  vpc_id                                         = local.vpc_id
  map_roles                                      = concat(var.map_roles, local.map_role)
  map_users                                      = var.map_users
  map_accounts                                   = var.map_accounts
  enable_irsa                                    = true
  attach_worker_cni_policy                       = var.cni_enabled
  cluster_endpoint_public_access                 = var.cluster_public_access
  cluster_endpoint_private_access                = !var.cluster_public_access
  cluster_create_endpoint_private_access_sg_rule = var.cluster_public_access
  cluster_endpoint_private_access_cidrs          = var.cluster_public_access ? [] : ["10.0.0.0/8"]

  tags = {
    Owner       = var.owner_tag
    Project     = var.project
    Environment = var.env
    Terraform   = true
  }

}

output "project_eks_cluster_id" {
  value = module.project_eks_cluster.cluster_id
}


resource "random_pet" "random" {
  count = length(local.subnet_ids)
  keepers = {
    name = "${local.subnet_ids[count.index]}-${var.eks_cluster_version}-${join("-", var.cluster_node_instance_type)}-${var.cluster_min_node_count}"
  }
  length = 1
}

resource "aws_eks_node_group" "project-eks-cluster-nodegroup" {
  count = length(local.subnet_ids)
  # version = "3.74.3"
  depends_on = [module.project_eks_cluster,
    aws_iam_role_policy_attachment.default-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.default-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.default-AmazonEC2ContainerRegistryReadOnly
  ]
  cluster_name         = "${var.eks_cluster_name}-${var.env}"
  node_group_name      = "node-group-${var.eks_cluster_name}-${var.env}-${random_pet.random[count.index].id}"
  node_role_arn        = aws_iam_role.eks-default-role.arn
  subnet_ids           = [local.subnet_ids[count.index]]
  instance_types       = var.cluster_node_instance_type
  disk_size            = var.cluster_node_disk_size
  capacity_type        = var.cluster_node_billing_mode
  force_update_version = true
  scaling_config {
    desired_size = var.cluster_min_node_count + 1
    max_size     = var.cluster_max_node_count
    min_size     = var.cluster_min_node_count
  }
  update_config {
    max_unavailable = 2
  }
  tags = {
    Owner                                                      = var.owner_tag
    Environment                                                = var.env
    Project                                                    = var.project
    Terraform                                                  = true
    "kubernetes.io/cluster/${var.eks_cluster_name}-${var.env}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                        = "true"
  }
  remote_access {
    ec2_ssh_key = aws_key_pair.bastion_key_pair.key_name
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }

}



## THANOS Config ###
/*
data "aws_kms_key" "aws_s3_key" {
  key_id = "alias/aws/s3"
}

module "test_bucket" {
  source = "git@github.com:xerris/aws-modules.git//s3"

  bucket        = "${var.env}-${var.project}"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.aws_kms_key.aws_s3_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_iam_policy" "eks-thanos-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-eks-thanos-policy"
  path        = "/"
  description = "${var.eks_cluster_name}-${var.env}-eks-thanos-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3Operations",
      "Action": [
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:PutObjectTagging",
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.env}-${var.project}/*",
        "arn:aws:s3:::${var.env}-${var.project}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "eks-thanos-role" {
  name = "${var.eks_cluster_name}-${var.env}-eks-thanos-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.project_eks_cluster.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "oidc.eks.${var.region}.amazonaws.com/id${regex("[^oidc-provider]+$", module.project_eks_cluster.oidc_provider_arn)}:sub": "system:serviceaccount:*:thanos-store"
        }
      }
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "thanos-Policy-attach" {
  policy_arn = aws_iam_policy.eks-thanos-policy.arn
  role       = aws_iam_role.eks-thanos-role.name
}
*/
## End Thanos config ##


#resource "aws_eks_identity_provider_config" "oidc_provider" {
#  cluster_name = module.project_eks_cluster.cluster_id
#
#  oidc {
#    client_id                     = module.project_eks_cluster.oidc_provider_arn
#    identity_provider_config_name = "oidc_provider-${var.eks_cluster_name}-${var.env}"
#    issuer_url                    =  module.project_eks_cluster.cluster_oidc_issuer_url
#  }
#}
