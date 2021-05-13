resource "aws_iam_role" "K8sFullAdmin-role" {
  name               = "${var.eks_cluster_name}-${var.env}-K8sFullAdmin"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "K8sClusterAdmin-role" {
  name               = "${var.eks_cluster_name}-${var.env}-K8sClusterAdmin"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "K8sDeveloper-role" {
  name               = "${var.eks_cluster_name}-${var.env}-K8sDeveloper"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
            "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "K8sFullAdmin-role-policy" {
  name = "${var.eks_cluster_name}-${var.env}-K8sFullAdmin-role-policy"
  role = aws_iam_role.K8sFullAdmin-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": "sts:GetCallerIdentity",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "K8sClusterAdmin-role-policy" {
  name = "${var.eks_cluster_name}-${var.env}-K8sClusterAdmin-role-policy"
  role = aws_iam_role.K8sClusterAdmin-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": "sts:GetCallerIdentity",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "K8sDeveloper-role-policy" {
  name = "${var.eks_cluster_name}-${var.env}-K8sDeveloper-role-policy"
  role = aws_iam_role.K8sDeveloper-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": "sts:GetCallerIdentity",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group" "K8sFullAdmin-group" {
  name = "${var.eks_cluster_name}-${var.env}-K8sFullAdmin"
}

resource "aws_iam_policy" "K8sFullAdmin-group-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-K8sFullAdmin-group-policy"
  description = "${var.eks_cluster_name}-${var.env}-K8sFullAdmin-group-policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_cluster_name}-${var.env}-K8sFullAdmin"
  }
}
  EOF
}

resource "aws_iam_group_policy_attachment" "K8sFullAdmin-group-policy-attach" {
  group      = aws_iam_group.K8sFullAdmin-group.name
  policy_arn = aws_iam_policy.K8sFullAdmin-group-policy.arn
}



resource "aws_iam_group" "K8sClusterAdmin-group" {
  name = "${var.eks_cluster_name}-${var.env}-K8sClusterAdmin"
}

resource "aws_iam_policy" "K8sClusterAdmin-group-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-K8sClusterAdmin-group-policy"
  description = "${var.eks_cluster_name}-${var.env}-K8sClusterAdmin-group-policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_cluster_name}-${var.env}-K8sClusterAdmin"
  }
}
  EOF
}

resource "aws_iam_group_policy_attachment" "K8sClusterAdmin-group-policy-attach" {
  group      = aws_iam_group.K8sClusterAdmin-group.name
  policy_arn = aws_iam_policy.K8sClusterAdmin-group-policy.arn
}


resource "aws_iam_group" "K8sDeveloper-group" {
  name = "${var.eks_cluster_name}-${var.env}-K8sDeveloper"
}

resource "aws_iam_policy" "K8sDeveloper-group-policy" {
  name        = "${var.eks_cluster_name}-${var.env}-K8sDeveloper-group-policy"
  description = "${var.eks_cluster_name}-${var.env}-K8sDeveloper-group-policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_cluster_name}-${var.env}-K8sDeveloper"
  }
}
  EOF
}

resource "aws_iam_group_policy_attachment" "K8sDeveloper-group-policy-attach" {
  group      = aws_iam_group.K8sDeveloper-group.name
  policy_arn = aws_iam_policy.K8sDeveloper-group-policy.arn
}