# resource "aws_ecr_repository" "freelance_ecr" {
#   name                 = "freelance-ecr"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# resource "aws_ecr_repository" "twimchat" {
#   name                 = "freelance-ecr/twimchat"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }