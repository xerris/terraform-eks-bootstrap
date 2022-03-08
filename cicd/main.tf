module "flux2"{
    #count = var.flux2 ? 1 : 0
    source = "./flux2"
    target_path = "${var.target_path}/${var.env}"
    repository_name = "terraform-eks-apps-bootstrap"
    repo_url = "https://github.com/${var.github_owner}/${var.repository_name}"
    branch = var.branch
    flux_token  = var.flux_token
    region =  var.region
    repo_provider = var.repo_provider
    components = var.components
    default_components = var.default_components
}