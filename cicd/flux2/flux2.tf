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
      version = "1.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
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
  labels_prefix            = var.labels_prefix
  flux2 = merge(
    {
      enabled                  = true
      create_ns                = true
      namespace                = "flux-system"
      target_path              = var.target_path
      default_network_policy   = true
      version                  = "v0.14.2"
      repo_url               = var.repo_url
      create_github_repository = false
      repository               = var.repository_name
      repository_visibility    = "public"
      branch                   = var.branch
      flux_sync_branch         = ""
      default_components       = var.default_components
      components               = var.components
      provider                 = var.repo_provider
      auto_image_update        = false
    },
    var.flux2
  )

  apply = local.flux2["enabled"] ? [for v in data.kubectl_file_documents.apply[0].documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null

  sync = local.flux2["enabled"] ? [for v in data.kubectl_file_documents.sync[0].documents : {
    data : yamldecode(v)
    content : v
    }
  ] : null
}

resource "kubernetes_namespace" "flux2" {
  count = local.flux2["enabled"] && local.flux2["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = local.flux2["namespace"]
    }

    name = local.flux2["namespace"]
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

data "flux_install" "main" {
  count          = local.flux2["enabled"] ? 1 : 0
  namespace      = local.flux2["namespace"]
  target_path    = local.flux2["target_path"]
  network_policy = false
  version        = local.flux2["version"]
  components     = distinct(concat(local.flux2["default_components"], local.flux2["components"], local.flux2["auto_image_update"] ? ["image-reflector-controller", "image-automation-controller"] : []))
}

# Split multi-doc YAML with
# https://registry.terraform.io/providers/gavinbunney/kubectl/latest
data "kubectl_file_documents" "apply" {
  count   = local.flux2["enabled"] ? 1 : 0
  content = data.flux_install.main[0].content
}

# Apply manifests on the cluster
resource "kubectl_manifest" "apply" {
  for_each   = local.flux2["enabled"] ? { for v in local.apply : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content } : {}
  depends_on = [kubernetes_namespace.flux2]
  yaml_body  = each.value
}

# Generate manifests
data "flux_sync" "main" {
  count       = local.flux2["enabled"] ? 1 : 0
  target_path = local.flux2["target_path"]
  url         = local.flux2["repo_url"]
  branch      = local.flux2["flux_sync_branch"] != "" ? local.flux2["flux_sync_branch"] : local.flux2["branch"]
  namespace   = local.flux2["namespace"]
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
  depends_on = [
    kubernetes_namespace.flux2,
    kubectl_manifest.apply
  ]
  yaml_body = each.value
}

# Generate a Kubernetes secret with the Git credentials
resource "kubernetes_secret" "main" {
  count      = local.flux2["enabled"] ? 1 : 0
  depends_on = [kubectl_manifest.apply]

  metadata {
    name      = data.flux_sync.main[0].name
    namespace = data.flux_sync.main[0].namespace
  }

  data = {
    username = "andrestorresGL"
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

resource "github_branch_default" "main" {
  count      = local.flux2["enabled"] && local.flux2["create_github_repository"] && (local.flux2["provider"] == "github") ? 1 : 0
  repository = local.flux2["create_github_repository"] ? github_repository.main[0].name : data.github_repository.main[0].name
  branch     = local.flux2["branch"]
}



output "data_github"{
  value = data.github_repository.main[0]
}

resource "kubernetes_network_policy" "flux2_allow_monitoring" {
  count = local.flux2["enabled"] && local.flux2["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]}-allow-monitoring"
    namespace = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "8080"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            "${local.labels_prefix}/component" = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux2_allow_namespace" {
  count = local.flux2["enabled"] && local.flux2["default_network_policy"] ? 1 : 0

  metadata {
    name      = "${local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]}-allow-namespace"
    namespace = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.flux2["create_ns"] ? kubernetes_namespace.flux2.*.metadata.0.name[count.index] : local.flux2["namespace"]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

