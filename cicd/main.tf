module "flux2_crd"{
    #count = var.flux2 ? 1 : 0
    source = "./flux2/flux2_crd"
    target_path = "${var.target_path}/${var.env}"
    components = var.components
    default_components = var.default_components
}

module "flux_repo_2048"{
    source = "./flux2/flux2_repos"
    repository_name = "2048-k8-app"
    repo_url = "https://github.com/${var.github_owner}/${var.repository_name}"
    branch = var.branch
    target_path = "${var.target_path}/${var.env}"
    flux_token  = var.flux_token
    repo_provider = var.repo_provider
    region =  var.region
    ready = module.flux2_crd.manifest_ready
}


module "flux_repo_addons"{
    source = "./flux2/flux2_repos"
    repository_name = "kubernetes-addons-bootstrap"
    repo_url = "https://github.com/${var.github_owner}/kubernetes-addons-bootstrap"
    branch = var.branch
    target_path = "${var.target_path}/${var.env}"
    flux_token  = var.flux_token
    repo_provider = var.repo_provider
    region =  var.region
    ready = module.flux2_crd.manifest_ready
}