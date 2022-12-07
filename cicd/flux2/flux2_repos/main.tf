terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version       = "2.2.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "0.2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "github" {
  token = var.flux_token
}


locals {

  flux2 = merge(
    {
      enabled                  = true
      create_ns                = true
      namespace                = "flux2-system"
      target_path              = var.target_path
      default_network_policy   = true
      version                  = "v0.27.3"
      repo_url               = var.repo_url
      create_github_repository = false
      repository               = var.repository_name
      repository_visibility    = "public"
      branch                   = var.branch
      flux_sync_branch         = ""
      provider                 = var.repo_provider
      auto_image_update        = false
    },
    var.flux2
  )

  sync = local.flux2["enabled"] ? [for v in data.kubectl_file_documents.sync[0].documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null
}

######## Configure Connection to Repo and branch ######


# Generate manifests
data "flux_sync" "main" {
  count       = local.flux2["enabled"] ? 1 : 0
  target_path = local.flux2["target_path"]
  url         = local.flux2["repo_url"]
  branch      = local.flux2["flux_sync_branch"] != "" ? local.flux2["flux_sync_branch"] : local.flux2["branch"]
  namespace   = local.flux2["namespace"]
  name = "${local.flux2["repository"]}-${local.flux2["branch"]}"
  secret = "${local.flux2["repository"]}-${local.flux2["branch"]}-secret"
}

# Split multi-doc YAML with
# https://registry.terraform.io/providers/gavinbunney/kubectl/latest
data "kubectl_file_documents" "sync" {
  count   = local.flux2["enabled"] ? 1 : 0
  content = data.flux_sync.main[0].content
}

# Apply manifests on the cluster
resource "kubectl_manifest" "sync" {
  for_each = local.flux2["enabled"] ? { for v in local.sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content } : {}
  yaml_body = each.value
}

# Generate a Kubernetes secret with the Git credentials
resource "kubernetes_secret" "main" {
  count      = local.flux2["enabled"] ? 1 : 0
  metadata {
   # name = "flux-secret"
    name      = data.flux_sync.main[0].secret
    namespace = data.flux_sync.main[0].namespace
  }

  data = {
    username = var.github_user
    password = var.flux_token
  }

}

# GitHub
resource "github_repository" "main" {
  count      = local.flux2["enabled"] && local.flux2["create_github_repository"] && (local.flux2["provider"] == "github") ? 1 : 0
  name       = local.flux2["repository"]
  visibility = local.flux2["repository_visibility"]
  auto_init  = true
}

data "github_repository" "main" {
  count = local.flux2["enabled"] && !local.flux2["create_github_repository"] && (local.flux2["provider"] == "github") ? 1 : 0
  full_name  = "${var.github_owner}/${var.repository_name}"
}

resource "github_branch" "main" {
  count      = local.flux2["enabled"] && local.flux2["create_github_repository"] && (local.flux2["provider"] == "github") ? 1 : 0
  repository = local.flux2["create_github_repository"] ? github_repository.main[0].name : data.github_repository.main[0].name
  branch     = local.flux2["branch"]
}



output "data_github"{
  value = data.github_repository.main[0]
}
