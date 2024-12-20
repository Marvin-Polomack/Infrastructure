module "github_action_iam_role" {
    source = "./modules/iam-role"

    github_org      = "Marvin-Polomack"
    repository_name = "Infrastructure"
}