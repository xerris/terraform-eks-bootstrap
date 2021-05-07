data "aws_eks_cluster" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.project_eks_cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

variable "vpc_data"{}

locals{
  vpc_id = var.create_vpc ? var.vpc_data.id : var.vpc_id
  subnet_ids = var.create_vpc ? var.vpc_data.subnet_ids : var.private_subnets_ids
}

module "project_eks_cluster" {
  depends_on = [module.vpc]
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.eks_cluster_name}-${var.env}"
  cluster_version = var.eks_cluster_version
  subnets         = local.subnet_ids
  vpc_id          = local.vpc_id

  tags = {
    Owner       = var.owner_tag
    Environment = var.env
    Terraform   = true
  }

}



resource "aws_eks_node_group" "project-eks-cluster-nodegroup" {
  count = length(local.subnet_ids)
  depends_on = [module.project_eks_cluster]
  cluster_name    = "${var.eks_cluster_name}-${var.env}"
  node_group_name = "node-group-${var.eks_cluster_name}-${local.subnet_ids[count.index].id}"
  node_role_arn   = aws_iam_role.eks-autoscale-role.arn
  subnet_ids      = [local.subnet_ids[count.index]]
  instance_types = [var.cluster_node_instance_type]
  ami_type  = var.cluster_node_image_id
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