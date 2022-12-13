
## FLux variables ##

variable "env" {
    default =  "dev"
}

variable "region" {
    default = "us-east-1"
}


variable "target_path" {
  default = "overlays"
}
variable "github_owner" {
  default = "xerris"
}

variable "github_user"{}

variable "repository_name" {
  default = "terraform-eks-apps-bootstrap-ginu"
}
variable "flux_token" {}

variable "branch" {
  default = "xdp-ginu-dev"
}

variable "repo_provider" {

}

variable "default_components" {
  type = list
}

variable "components" {
  type = list
}