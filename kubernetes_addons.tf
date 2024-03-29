data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni", "coredns"])

  addon_name         = each.value
  kubernetes_version = module.project_eks_cluster.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "default" {
  for_each = toset(["kube-proxy"])

  addon_name         = each.value
  kubernetes_version = module.project_eks_cluster.cluster_version
  most_recent        = false
}

module "eks_blueprints_kubernetes_addons" {
  depends_on = [
    #aws_route53_zone.ens_hosted_zone,
    aws_eks_node_group.project-eks-cluster-nodegroup
  ]
  count = var.install_addons? 1:0
  source               = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons"
  eks_cluster_id       = module.project_eks_cluster.cluster_id
  eks_cluster_endpoint = module.project_eks_cluster.cluster_endpoint
  eks_oidc_provider    = replace(module.project_eks_cluster.cluster_oidc_issuer_url, "https://", "")
  eks_cluster_version  = module.project_eks_cluster.cluster_version

  # EKS Addons

  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_vpc_cni            = true
  enable_aws_efs_csi_driver            = false
  enable_aws_cloudwatch_metrics        = true
  enable_prometheus                    = true
  enable_amazon_prometheus             = var.create_managed_prometheus
  enable_app_2048                      = true
  amazon_prometheus_workspace_endpoint = module.managed_prometheus.workspace_prometheus_endpoint

  #K8s Add-ons
  enable_argocd                       = false
  enable_aws_for_fluentbit            = false
  enable_aws_load_balancer_controller = false
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_spark_k8s_operator           = false
  enable_external_dns                 = false



  #external_dns_route53_zone_arns = [
  #  aws_route53_zone.ens_hosted_zone.arn
  #]
  #eks_cluster_domain = aws_route53_zone.ens_hosted_zone.name
  #external_dns_helm_config = {
  #  name                       = "external-dns"
  #  chart                      = "external-dns"
  #  repository                 = "https://charts.bitnami.com/bitnami"
  #  version                    = "6.1.6"
  #  namespace                  = "external-dns"
  #  set = [
  #    {
  #      name = "sources[0]"
  #      value = "ingress"
  #    }
  #  ]
  #}
  #prometheus_helm_config = {
  #  name       = "prometheus"                                         # (Required) Release name.
  #  repository = "https://prometheus-community.github.io/helm-charts" # (Optional) Repository URL where to locate the requested chart.
  #  chart      = "prometheus"                                         # (Required) Chart name to be installed.
  #  version    = "15.10.1"                                            # (Optional) Specify the exact chart version to install. If this is not specified, it defaults to the version set within default_helm_config: https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/main/modules/kubernetes-addons/prometheus/locals.tf
  #  namespace  = "prometheus"                                         # (Optional) The namespace to install the release into.
  #  #values = [templatefile("${path.module}/prometheus-values.yaml", {
  #  #  operating_system = "linux"
  #  #})]
  #}

  amazon_eks_kube_proxy_config = {
    addon_version     = data.aws_eks_addon_version.default["kube-proxy"].version
    resolve_conflicts = "OVERWRITE"
  }
  amazon_eks_coredns_config = {
    addon_version     = data.aws_eks_addon_version.latest["coredns"].version
    resolve_conflicts = "OVERWRITE"
  }
  amazon_eks_vpc_cni_config = {
    addon_version     = data.aws_eks_addon_version.latest["vpc-cni"].version
    resolve_conflicts = "OVERWRITE"
  }
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "extraArgs.expander"
        value = "priority"
      },
      {
        name  = "expanderPriorities"
        value = <<-EOT
                    100:
                      - .*-spot-2vcpu-8mem.*
                    90:
                      - .*-spot-4vcpu-16mem.*
                    10:
                      - .*
                  EOT
      }
    ]
  }

  #Name of the AWS Secrets manager parameter that holds the ArgoCD admin password
  #argocd_admin_password_secret_name = "argocd_admin_password"

  # Configuration for the ArgoCD install
  argocd_helm_config = {
    name       = "argo-cd"
    chart      = "argo-cd"
    repository = "https://argoproj.github.io/argo-helm"
    #version = "5.5.8"
    #namespace = "argocd"
    timeout          = "1200"
    create_namespace = true
    #set_sensitive = [
    #  {
    #    name  = "configs.secret.argocdServerAdminPassword"
    #    value = bcrypt(data.aws_secretsmanager_secret_version.argocd_adminpw_version.secret_string)
    #  }
    #]
    set = [
      {
        name  = "server.service.type"
        value = "NodePort"
      },
      {
        name  = "server.extraArgs[0]"
        value = "--insecure"
      },
      {
        name  = "redis.affinity"
        value = "{}"
      },
      {
        name  = "configs.knownHosts.data.ssh_known_hosts"
        value = "something.com ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
      },
      {
        name  = "server.ingress.enabled"
        value = true
      },
      {
        name  = "server.ingress.https"
        value = true
      },
      {
        name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
        value = "alb"
      },
      #          {
      #            name = "server.ingress.annotations.kubernetes\\.io/actions\\.ssl-redirect"
      #            value = "'{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}'"
      #          },
      {
        name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
        value = "internet-facing"
      },
      {
        name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-protocol"
        value = "HTTPS"
      },
      {
        name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-port"
        value = "traffic-port"
      },
      # {
      #   name = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
      #   value = aws_acm_certificate.ens_cert.arn
      # },
      {
        name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
        value = "[{\"HTTP\": 80}\\,{\"HTTPS\": 443}]"
      },
      #{
      #  name = "server.ingress.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
      #  value = "argocd.${aws_route53_zone.ens_hosted_zone.name}"
      #},
      #{
      #  name = "server.ingress.hosts[0]"
      #  value = "argocd.${aws_route53_zone.ens_hosted_zone.name}"
      #},
      {
        name  = "server.ingress.paths[0]"
        value = "/"
      }

    ]
  }

}


module "managed_prometheus" {
  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "~> 2.1"
  count = var.create_managed_prometheus? 1:0
  workspace_alias = "${var.eks_cluster_name}-${var.env}"

  tags = {
    Owner       = var.owner_tag
    Project     = var.project
    Environment = var.env
    Terraform   = true
  }
}
