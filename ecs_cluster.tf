# resource "aws_launch_template" "freelance_ecs_instance" {
#   name_prefix   = "freelance-ecs-instance"
#   image_id      = data.aws_ami.amazon_linux_2023.image_id
#   instance_type = "t3.micro" # Free-tier eligible

#   iam_instance_profile {
#     arn = aws_iam_instance_profile.twim_chat_ecs_node_profile.arn
#   }

#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [aws_security_group.k8s_sg.id]
#   }

#   user_data = filebase64("./scripts/freelance-ecs-instance.sh")
# }

# resource "aws_ecs_cluster" "freelance_ecs_cluster" {
#   name = "freelance-ecs-cluster"
# }

# resource "aws_autoscaling_group" "twim_asg" {
#   name = "twim-asg"
#   launch_template {
#     id      = aws_launch_template.freelance_ecs_instance.id
#     version = "$Latest"
#   }

#   vpc_zone_identifier = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
#   min_size            = 1
#   max_size            = 1
#   desired_capacity    = 1
# }

# resource "aws_ecs_task_definition" "twim_chat_task" {
#   family                   = "twim-chat-task"
#   network_mode             = "awsvpc"
#   task_role_arn            = aws_iam_role.twim_chat_ecs_task_role.arn
#   execution_role_arn       = aws_iam_role.twim_chat_ecs_exec_role.arn
#   container_definitions    = jsonencode([
#     {
#       name: "twim-chat-container",
#       image: "216989096559.dkr.ecr.eu-west-3.amazonaws.com/freelance-ecr/twimchat:latest",
#       cpu: 256,
#       memory: 512,
#       portMappings: [
#         {
#           containerPort: 3000,
#           hostPort: 3000
#         }
#       ]
#     }
#   ])
# }

# resource "aws_ecs_service" "twim_chat_service" {
#   name            = "twim-chat-service"
#   cluster         = aws_ecs_cluster.freelance_ecs_cluster.id
#   task_definition = aws_ecs_task_definition.twim_chat_task.arn

#   desired_count = 1

#   network_configuration {
#    subnets         = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
#    security_groups = [aws_security_group.k8s_sg.id]
#  }

#  force_new_deployment = true
#  placement_constraints {
#    type = "distinctInstance"
#  }

#  triggers = {
#    redeployment = timestamp()
#  }

#  capacity_provider_strategy {
#    capacity_provider = aws_ecs_capacity_provider.twim_chat_capacity_provider.name
#    weight            = 100
#  }

#  load_balancer {
#    target_group_arn = module.twim_alb.target_group_arn
#    container_name   = "twim-chat-container"
#    container_port   = 3000
#  }

#  depends_on = [aws_autoscaling_group.twim_asg]
# }

# resource "aws_ecs_capacity_provider" "twim_chat_capacity_provider" {
#  name = "twim-chat-capacity-provider"

#  auto_scaling_group_provider {
#    auto_scaling_group_arn = aws_autoscaling_group.twim_asg.arn

#    managed_scaling {
#      maximum_scaling_step_size = 1000
#      minimum_scaling_step_size = 1
#      status                    = "ENABLED"
#      target_capacity           = 1
#    }
#  }
# }

# resource "aws_ecs_cluster_capacity_providers" "twim_chat_cluster_capacity_providers" {
#  cluster_name = aws_ecs_cluster.freelance_ecs_cluster.name

#  capacity_providers = [aws_ecs_capacity_provider.twim_chat_capacity_provider.name]

#  default_capacity_provider_strategy {
#    base              = 1
#    weight            = 100
#    capacity_provider = aws_ecs_capacity_provider.twim_chat_capacity_provider.name
#  }
# }

# # --- ECS Node Role ---

# data "aws_iam_policy_document" "twim_chat_ecs_node_doc" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "twim_chat_ecs_node_role" {
#   name_prefix        = "twim-chat-ecs-node-role"
#   assume_role_policy = data.aws_iam_policy_document.twim_chat_ecs_node_doc.json
# }

# resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
#   role       = aws_iam_role.twim_chat_ecs_node_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_instance_profile" "twim_chat_ecs_node_profile" {
#   name_prefix = "twim-chat-ecs-node-profile"
#   path        = "/ecs/instance/"
#   role        = aws_iam_role.twim_chat_ecs_node_role.name
# }

# # --- ECS Task Role ---

# data "aws_iam_policy_document" "twim_chat_ecs_task_doc" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "twim_chat_ecs_task_role" {
#   name_prefix        = "twim-chat-ecs-task-role"
#   assume_role_policy = data.aws_iam_policy_document.twim_chat_ecs_task_doc.json
# }

# resource "aws_iam_role" "twim_chat_ecs_exec_role" {
#   name_prefix        = "twim-chat-ecs-exec-role"
#   assume_role_policy = data.aws_iam_policy_document.twim_chat_ecs_task_doc.json
# }

# resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
#   role       = aws_iam_role.twim_chat_ecs_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }