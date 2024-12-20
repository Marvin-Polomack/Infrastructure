module "infrastructure_github_action_iam_role" {
    source = "./modules/iam-role"

    github_org      = "Marvin-Polomack"
    repository_name = "Infrastructure"
}

module "theworldismind_github_action_iam_role" {
    source = "./modules/iam-role"

    github_org      = "Marvin-Polomack"
    repository_name = "theworldismind.com"
}