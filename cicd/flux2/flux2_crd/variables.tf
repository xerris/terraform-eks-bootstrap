variable "target_path" {
  default = "apps"
}

variable "default_components" {
  type = list
}

variable "components" {
  type = list
}

variable "labels_prefix" {
  description = "Custom label prefix used for network policy namespace matching"
  type        = string
  default     = "project.eks"
}

variable "flux2" {
  description = "Customize Flux chart, see `flux2.tf` for supported values"
  type        = any
  default     = {}
}