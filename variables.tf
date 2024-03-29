variable "env" {
  default = "dev"
}

variable "project" {
  default = "xerris_internal"
}

variable "create_vpc" {
  default = true
}

variable "vpc_id" {
  default = ""
}

variable "create_managed_prometheus"{
  type = bool
  default = false
}

variable "install_addons"{
  type = bool
  default = false
}


variable "cluster_public_access" {
  type = bool
}

variable "cni_enabled" {
  type = bool
}

variable "eks_master_role" {
  type = string
}

variable "private_subnets_ids" {
  default = []
  type    = list(any)
}

variable "public_subnets_ids" {
  default = []
  type    = list(any)
}

variable "region" {
  default = "us-east-1"
}

variable "vpc_name" {
  default = "project_eks_vpc"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "private_subnets" {
  type    = list(any)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "public_subnets" {
  type    = list(any)
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "enable_natgateway" {
  default = true
}

variable "enable_vpngateway" {
  default = false
}

variable "external_nat_ip_ids" {
  default = [""]
  type    = list(any)
}
variable "count_eip_nat" {
  default = 1
}

variable "owner_tag" {
  default = "DevOps Team"
}

variable "ecr_name" {
  default = "project_eks_ecr"
}

variable "eks_cluster_name" {
  default = "project_eks_cluster"
}

variable "eks_cluster_version" {
  default = "1.19.8"
}

variable "cluster_min_node_count" {
  default = 1
}

variable "cluster_max_node_count" {
  default = 2
}

variable "cluster_node_instance_type" {
  type    = list(string)
  default = []
}

variable "cluster_node_billing_mode" {
  default = "SPOT" #ON_DEMAND
}

variable "cluster_node_disk_size" {
  default = "200"
}

variable "create_bastion" {
  default = 1
}

variable "bucket_cluster_logs_name" {
  default = "project_eks_logs"
}

variable "cluster_logs_path" {
  default = "cluster_logs"
}

variable "node_logs_path" {
  default = "node_logs"
}

variable "monthly_billing_threshold" {
  default = 500
}

variable "billing_currency" {
  default = "USD"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = []
}

variable "role_name" {
  default = "test_role"
}

variable "api_groups" {
  type    = list(any)
  default = []
}

variable "resources" {
  type    = list(any)
  default = []
}

variable "resource_names" {
  type    = list(any)
  default = []
}

variable "actions" {
  type    = list(any)
  default = []
}


variable "namespace_name" {
  default = "default"
}

variable "username" {
  default = []
}

variable "dev_users" {
  default = []
}

variable "create_db" {
  default = false
}

variable "rds_cluster_name" {

}

variable "rds_engine" {
  default = "aurora-mysql"
}

variable "engine_version" {
  default = "5.7.mysql_aurora.2.03.2"

}


variable "db_name" {

}

variable "db_master_user" {

}

variable "db_backup_retention" {
  default = 5
}

variable "db_backup_window" {
  default = "07:00-09:00"
}


## FLux variables ##

variable "target_path" {
  default = "apps"
}
variable "github_owner" {
  default = "xerris"
}
variable "repository_name" {
  default = "terraform-eks-apps-bootstrap"
}

variable "branch" {
  default = "main"
}

variable "repo_provider" {

}

variable "default_components" {
  type = list(any)
}

variable "components" {
  type = list(any)
}