env = "dev"
create_vpc = true
region = "us-east-1"
vpc_name = "project_eks_vpc"
vpc_subnet = "10.1.0.0/16"
private_subnets = ["10.1.1.0/24","10.1.2.0/24"]
public_subnets = ["10.1.3.0/24","10.1.4.0/24"]
enable_natgateway = true
enable_vpngateway = false
count_eip_nat = 1
owner_tag = "Xerris DevOps Team"
ecr_name = "project_eks_ecr"
eks_cluster_name = "project_eks_cluster"
eks_cluster_version  = "1.19"
cluster_min_node_count = 3
cluster_max_node_count = 4
cluster_node_instance_type = "m5.large"
cluster_node_billing_mode = "SPOT"
cluster_node_image_id = "ami-048f6ed62451373d9"
cluster_node_disk_size = "200"
bucket_cluster_logs_name = "project_eks_logs"
cluster_logs_path = "cluster_logs"
node_logs_path = "node_logs"
monthly_billing_threshold = 500
billing_currency = "USD"
create_bastion = 1
map_roles = [
  #{
  #  rolearn  = "arn:aws:iam::471337104212:role/project_eks_cluster-dev-K8sFullAdmin"
  #  username = "project_eks_cluster-dev-K8sFullAdmin"
  #  groups   = ["system:masters"]
  #}
  ]

map_users = [
  {
    userarn  = "arn:aws:iam::471337104212:user/circleci"
    username = "kubernetes-service-account"
    groups   = ["system:masters"]
  }
]