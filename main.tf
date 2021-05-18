data "aws_eks_cluster" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}



locals{
  depends_on = [module.vpc]
  vpc_id = var.create_vpc ? module.vpc.vpc_id : var.vpc_id
  subnet_ids = var.create_vpc ? module.vpc.private_subnets : var.private_subnets_ids
  public_subnet_ids = var.create_vpc ? module.vpc.public_subnets : var.public_subnets_ids
  map_role = [{
    rolearn  =  aws_iam_role.eks-autoscale-role.arn
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
    username = " adminuser:{{SessionName}}"
    groups   = ["ad-cluster-admins"]
  },
  {
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/project_eks_cluster-dev-K8sDeveloper"
    username = "devuser:{{SessionName}}"
    groups   = ["ad-cluster-devs"]
  }
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
  value = tls_private_key.this.private_key_pem
  sensitive = true
}

resource "aws_security_group" "bastion" {
  name        = "bastion-security-group"
  description = "Allow SSH traffic"
  vpc_id = local.vpc_id
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
    Environment = var.env
    Terraform   = true
  }
}


module "ec2_cluster" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"
  name                   = "bastion"
  instance_count         = 1
  ami           = var.cluster_node_image_id
  instance_type          = "t2.micro"
  key_name      = aws_key_pair.bastion_key_pair.key_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = local.public_subnet_ids[0]
  tags = {
    Owner       = var.owner_tag
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
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.eks_cluster_name}-${var.env}"
  cluster_version = var.eks_cluster_version
  subnets         = local.subnet_ids
  vpc_id          = local.vpc_id
  map_roles =   concat(var.map_roles, local.map_role)
  map_users    = var.map_users
  map_accounts = var.map_accounts

  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }

}

output "project_eks_cluster_id"{
  value = module.project_eks_cluster.cluster_id
}


resource "aws_eks_node_group" "project-eks-cluster-nodegroup" {
  count = length(local.subnet_ids)
  depends_on = [module.project_eks_cluster,
    aws_iam_role_policy_attachment.autoscale-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.autoscale-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.autoscale-AmazonEC2ContainerRegistryReadOnly,
  ]
  cluster_name    = "${var.eks_cluster_name}-${var.env}"
  node_group_name = "node-group-${var.eks_cluster_name}-${count.index}"
  node_role_arn   = aws_iam_role.eks-autoscale-role.arn
  subnet_ids      = [local.subnet_ids[count.index]]
  instance_types = [var.cluster_node_instance_type]
  disk_size = var.cluster_node_disk_size

  scaling_config {
    desired_size = var.cluster_min_node_count
    max_size     = var.cluster_max_node_count
    min_size     = var.cluster_min_node_count
  }

  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
    "kubernetes.io/cluster/${var.eks_cluster_name}-${var.env}" = "owned"
  }
  remote_access {
    ec2_ssh_key = aws_key_pair.bastion_key_pair.key_name
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }

}

resource "aws_iam_policy" "eks-autoscale-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-eks-autoscale-policy"
  path        = "/"
  description = "${var.eks_cluster_name}-${var.env}-eks-autoscale-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "eks-cert-route53-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-eks-cert-route53-policy"
  path        = "/"
  description = "${var.eks_cluster_name}-${var.env}-eks-cert-route53-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "route53:GetChange",
            "Resource": "arn:aws:route53:::change/*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "eks-autoscale-role" {
  name = "${var.eks_cluster_name}-${var.env}-eks-autoscale-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "autoscale-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-autoscale-role.name
}
resource "aws_iam_role_policy_attachment" "autoscale-eks-route53Policy" {
  policy_arn = aws_iam_policy.eks-cert-route53-policy.arn
  role       = aws_iam_role.eks-autoscale-role.name
}

resource "aws_iam_role_policy_attachment" "autoscale-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-autoscale-role.name
}

resource "aws_iam_role_policy_attachment" "autoscale-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-autoscale-role.name
}

resource "aws_iam_role_policy_attachment" "autoscale-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-autoscale-role.name
}

resource "aws_iam_role_policy_attachment" "autoscale-eks-autoscale-policy" {
  policy_arn = aws_iam_policy.eks-autoscale-policy.arn
  role       = aws_iam_role.eks-autoscale-role.name
}