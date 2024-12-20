module "infrastructure_github_action_iam_role" {
    source = "./modules/iam-role"

    github_org      = "Marvin-Polomack"
    repository_name = "Infrastructure"
    create_oidc     = true
}

module "theworldismind_github_action_iam_role" {
    source = "./modules/iam-role"

    github_org        = "Marvin-Polomack"
    repository_name   = "theworldismind.com"
    oidc_provider_arn = module.infrastructure_github_action_iam_role.role_arn
}