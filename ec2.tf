resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "k8s_vpc"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
}

resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s_security_group"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "ec2_k8s" {
  ami                    = data.aws_ami.amazon_linux_2023.image_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo apt-get update -y
              sudo apt-get upgrade -y

              # Install Docker
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update -y
              sudo apt-get install -y docker-ce
              sudo usermod -aG docker ubuntu

              # Enable Docker service
              sudo systemctl enable docker
              sudo systemctl start docker

              # Install kubeadm, kubelet, and kubectl
              sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
              sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
              deb https://apt.kubernetes.io/ kubernetes-xenial main
              EOF'

              sudo apt-get update -y
              sudo apt-get install -y kubelet kubeadm kubectl
              sudo apt-mark hold kubelet kubeadm kubectl

              # Initialize Kubernetes master
              sudo kubeadm init --pod-network-cidr=10.244.0.0/16

              # Setup kubeconfig for ubuntu user
              mkdir -p /home/ubuntu/.kube
              sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
              sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

              # Install Weave Net as a pod network
              kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')

              EOF

  tags = {
    Name = "ec2_k8s"
  }
}

output "master_instance_public_ip" {
  value = aws_instance.ec2_k8s.public_ip
}

output "kubeconfig_command" {
  value = "ssh -i ~/.ssh/your_key_pair.pem ubuntu@${aws_instance.ec2_k8s.public_ip} 'cat /home/ubuntu/.kube/config'"
}
