env = "dev"
create_vpc = true
region = "us-east-1"
vpc_name = "project_eks_vpc_Ginu"
vpc_cidr = "10.1.0.0/16"
project = "xerris"
#vpc_id   = "vpc-088c6886a69f9c128"
#private_subnets_ids = ["subnet-0e6c47a42ca1d4920"]
#public_subnets_ids = ["subnet-0e6c47a42ca1d4920"]
cluster_public_access = true
cni_enabled = true
private_subnets = ["10.1.1.0/24","10.1.2.0/24"]
public_subnets = ["10.1.3.0/24","10.1.4.0/24"]
enable_natgateway = true
enable_vpngateway = false
count_eip_nat = 1
owner_tag = "Ginu"
ecr_name = "project_eks_ecr_ginu"
eks_cluster_name = "project_eks_cluster_ginu3"
eks_cluster_version  = "1.23"
cluster_min_node_count = 1
cluster_max_node_count = 3
cluster_node_instance_type = ["t3a.medium","t3a.xlarge"]
cluster_node_billing_mode = "SPOT"
cluster_node_disk_size = "200"
bucket_cluster_logs_name = "project_eks_logs"
cluster_logs_path = "cluster_logs"
node_logs_path = "node_logs"
monthly_billing_threshold = 200
billing_currency = "USD"
create_bastion = 1
rds_cluster_name = "project-eks-rds"
db_name = "projecteksdb"
db_master_user = "projecteksmasteruser"
eks_master_role = "arn:aws:iam::370365354210:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_c87e108deaf1b7ca"
map_roles = [
   /*{
    rolearn  = "arn:aws:iam::471337104212:role/observability_eks_cluster-dev-K8sFullAdmin"
    username = "observability_eks_cluster-dev-K8sFullAdmin"
    groups   = ["system:masters"]
   }*/
  ]

map_users = [
  {
    userarn  = "arn:aws:iam::370365354210:user/deployment-user"
    username = "kubernetes-service-account"
    groups   = ["system:masters"]
  },
  {
    userarn  = "arn:aws:iam::370365354210:user/andres"
    username = "observability_eks_cluster-dev-K8sFullAdmin"
    groups   = ["system:masters"]
  }
]

## Flux variables ##

target_path = "/overlays"
github_owner = "xerris"
repository_name = "2048-k8-app"
branch= "dev"
repo_provider =  "github"
default_components = ["source-controller", "kustomize-controller", "notification-controller"]
components = ["helm-controller"]