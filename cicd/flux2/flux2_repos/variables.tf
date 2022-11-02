variable "target_path" {
  default = "overlays"
}
variable "github_owner" {
  default = "xerris"
}
variable "repository_name" {
  default = "terraform-eks-apps-bootstrap"
}
variable "flux_token" {}

variable "branch" {
  default = "main"
}
variable "github_user"{}
variable "region"{}
variable "flux2" {
  description = "Customize Flux chart, see `flux2.tf` for supported values"
  type        = any
  default     = {}
}

variable "labels_prefix" {
  description = "Custom label prefix used for network policy namespace matching"
  type        = string
  default     = "project.eks"
}

variable "repo_url" {
}

variable "repo_provider" {

}

variable "ready"{}