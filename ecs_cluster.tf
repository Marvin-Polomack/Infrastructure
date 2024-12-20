resource "aws_launch_template" "freelance_ecs_instance" {
  name_prefix   = "freelance-ecs-instance"
  image_id      = data.aws_ami.amazon_linux_2023.image_id
  instance_type = "t3.micro" # Free-tier eligible

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.k8s_sg.id]
  }

  user_data = base64encode(<<EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras enable ecs
              yum install -y ecs-init
              systemctl enable --now ecs
              EOF
  )
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

resource "aws_ecs_task_definition" "twim_chat_task" {
  family                   = "twim-chat-task"
  network_mode             = "bridge"
  container_definitions    = jsonencode(
    [
      {
      family: "twim-chat-task"
      containerDefinitions: [
        {
          name: "twim-chat-container"
          image: "216989096559.dkr.ecr.eu-west-3.amazonaws.com/freelance-ecr/twimchat:latest"
          cpu: 10
          memory: 512
          portMappings: [
            {
              containerPort: 3000
              hostPort: 3000
            }
          ]
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "twim_chat_service" {
  name            = "twim-chat-service"
  cluster         = aws_ecs_cluster.freelance_ecs_cluster.id
  task_definition = aws_ecs_task_definition.twim_chat_task.arn
  launch_type     = "EC2"

  desired_count = 1
}