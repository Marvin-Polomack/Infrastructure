# module "twim_alb" {
#   source = "./modules/alb"

#   name    = "twim-alb"
#   subnets = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
#   vpc_id  = aws_vpc.k8s_vpc.id
#   certificate_arn = aws_acm_certificate.main_cert.arn
# }