module "flux2_crd"{
    #count = var.flux2 ? 1 : 0
    source = "./flux2/flux2_crd"
    target_path = "${var.target_path}/${var.env}"
    components = var.components
    default_components = var.default_components
}

module "flux_repo_2048"{
    source = "./flux2/flux2_repos"
    repository_name = "terraform-eks-apps-bootstrap"
    repo_url = "https://github.com/${var.github_owner}/${var.repository_name}"
    branch = var.branch
    flux_token  = var.flux_token
    repo_provider = var.repo_provider
    region =  var.region
    ready = module.flux2_crd.manifest_ready
}
