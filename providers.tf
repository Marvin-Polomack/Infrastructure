provider "aws" {
    region = "eu-west-3"

    access_key = data.hcp_vault_secrets_app.freelance.secrets["aws_admin_frelance_access_key"]
    secret_key = data.hcp_vault_secrets_app.freelance.secrets["aws_admin_frelance_secret_key"]
}