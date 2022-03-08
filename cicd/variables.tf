
## FLux variables ##

variable "env" {
    default =  "dev"
}

variable "region" {
    default = "us-east-1"
}


variable "target_path" {
  default = "apps"
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

variable "repo_provider" {

}

variable "default_components" {
  type = list
}

variable "components" {
  type = list
}