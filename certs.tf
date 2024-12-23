resource "aws_acm_certificate" "main_cert" {
  domain_name       = "theworldismind.com"
  subject_alternative_names = ["www.theworldismind.com"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}