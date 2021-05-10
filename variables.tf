variable "account_id"{
    default = "471337104212"
}
variable "env" {
    default =  "dev"
}

variable "create_vpc" {
  default = true
}

variable "vpc_id" {
  default = ""
}

variable "private_subnets_ids" {
  default = []
  type = list
}

variable "public_subnets_ids" {
  default = []
  type = list
}

variable "region" {
    default = "us-east-1"
}

variable "vpc_name" {
    default = "project_eks_vpc"
}

variable "vpc_subnet" {
    default = "10.1.0.0/16"
}

variable "private_subnets"{
    type = list
    default = ["10.1.1.0/24","10.1.2.0/24"]
}

variable "public_subnets"{
    type = list
    default = ["10.1.3.0/24","10.1.4.0/24"]
}

variable "enable_natgateway" {
  default = true
}

variable "enable_vpngateway" {
  default = false
}

variable "external_nat_ip_ids" {
  default = [""]
  type = list
}
variable "count_eip_nat" {
  default = 1
}

variable "owner_tag" {
    default = "DevOps Team"
}

variable "ecr_name"{
    default =  "project_eks_ecr"
}

variable "eks_cluster_name" {
    default = "project_eks_cluster"
}

variable "eks_cluster_version" {
    default = "1.19.8"
}

variable "cluster_min_node_count" {
    default = 3
}

variable "cluster_max_node_count" {
    default = 5
}

variable "cluster_node_instance_type" {
    default = "m5.large"
}

variable "cluster_node_billing_mode" {
    default = "spot"
}

variable "cluster_node_image_id" {
    default = "ami-048f6ed62451373d9"
}
variable "cluster_node_disk_size"{
    default = "200"
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