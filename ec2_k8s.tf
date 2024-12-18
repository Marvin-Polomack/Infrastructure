module "ec2_k8s" {
  source = "./modules/ec2"
  ami                    = data.aws_ami.amazon_linux_2023.image_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

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

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Set up kubeconfig for root user
              export KUBECONFIG=/etc/kubernetes/admin.conf

              # Upload kubeconfig to S3
              aws s3 cp /etc/kubernetes/admin.conf s3://${aws_s3_bucket.kubeconfig_bucket.bucket_domain_name}/kubeconfig-$(hostname)-$(date +%Y-%m-%d).conf

              EOF

  tags = {
    Name = "ec2_k8s"
  }
}