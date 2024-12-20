resource "aws_launch_template" "freelance_ecs_instance" {
  name_prefix   = "freelance-ecs-instance"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro" # Free-tier eligible

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs.id]
  }

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras enable ecs
yum install -y ecs-init
systemctl enable --now ecs
EOF
}

resource "aws_ecs_cluster" "freelance_ecs_cluster" {
  name = "freelance-ecs-cluster"
}

resource "aws_autoscaling_group" "ecs_asg" {
  launch_template {
    id      = aws_launch_template.freelance_ecs_instance.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private_subnet.id]
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
}

# resource "aws_ecs_task_definition" "example" {
#   family                   = "example-task"
#   network_mode             = "bridge"
#   container_definitions    = <<DEFINITION
# [
#   {
#     "name": "nginx",
#     "image": "nginx:latest",
#     "memory": 128,
#     "cpu": 128,
#     "essential": true,
#     "portMappings": [
#       {
#         "containerPort": 80,
#         "hostPort": 80
#       }
#     ]
#   }
# ]
# DEFINITION
# }

# resource "aws_ecs_service" "example" {
#   name            = "example-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.example.arn
#   launch_type     = "EC2"

#   desired_count = 1
# }