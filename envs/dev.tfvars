env = "dev"
create_vpc = false
region = "ca-central-1"
vpc_name = "project_eks_vpc"
#vpc_cidr = "10.0.0.0/16"
vpc_id   = "vpc-088c6886a69f9c128"
private_subnets_ids = ["subnet-0e6c47a42ca1d4920"]
public_subnets_ids = ["subnet-0e6c47a42ca1d4920"]
#private_subnets = ["10.1.1.0/24","10.1.2.0/24"]
#public_subnets = ["10.1.3.0/24","10.1.4.0/24"]
enable_natgateway = true
enable_vpngateway = false
count_eip_nat = 1
owner_tag = "Xerris DevOps Team"
ecr_name = "project_eks_ecr"
eks_cluster_name = "project_eks_cluster"
eks_cluster_version  = "1.20"
cluster_min_node_count = 1
cluster_max_node_count = 2
cluster_node_instance_type = ["t3a.medium","t3a.large"]
cluster_node_billing_mode = "SPOT"
cluster_node_disk_size = "200"
bucket_cluster_logs_name = "project_eks_logs"
cluster_logs_path = "cluster_logs"
node_logs_path = "node_logs"
monthly_billing_threshold = 500
billing_currency = "USD"
create_bastion = 1
rds_cluster_name = "project_eks_rds"
db_name = "project_eks_db"
db_master_user = "project_eks_master_user"
map_roles = [
  #{
  #  rolearn  = "arn:aws:iam::471337104212:role/project_eks_cluster-dev-K8sFullAdmin"
  #  username = "project_eks_cluster-dev-K8sFullAdmin"
  #  groups   = ["system:masters"]
  #}
  ]

map_users = [
  {
    userarn  = "arn:aws:iam::209010588440:user/deployment-user"
    username = "kubernetes-service-account"
    groups   = ["system:masters"]
  }
]

