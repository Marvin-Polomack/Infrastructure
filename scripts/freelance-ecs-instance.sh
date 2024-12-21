#!/bin/bash
sudo dnf update -y
sudo dnf install -y ecs-init docker
sudo systemctl enable --now docker
sudo echo ECS_CLUSTER=freelance-ecs-cluster >> /etc/ecs/ecs.config
sudo systemctl enable --now ecs
sleep 30
sudo systemctl stop ecs
sudo systemctl start ecs