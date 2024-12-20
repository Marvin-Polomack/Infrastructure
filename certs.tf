resource "aws_acm_certificate" "cert" {
  domain_name       = "theworldismind.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}