module "flux2"{
    source = "./cicd/flux2"
    target_path = "${var.target_path}/${var.env}"
    repository_name = "terraform-eks-apps-bootstrap"
    repo_url = "https://github.com/${var.github_owner}/${var.repository_name}"
    branch = var.branch
    flux_token  = var.flux_token
    region =  var.region
    repo_provider = var.repo_provider
    components = var.components
    default_components = var.default_components
    cluster_name = "${var.eks_cluster_name}-${var.env}"
    cluster_endpoint = module.project_eks_cluster.cluster_endpoint
    cluster_ca_cert = module.project_eks_cluster.cluster_certificate_authority_data

}