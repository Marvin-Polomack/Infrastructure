data "aws_ami" "amazon_linux_2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}