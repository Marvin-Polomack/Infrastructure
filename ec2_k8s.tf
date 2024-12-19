module "ec2_k8s" {
  source = "./modules/ec2"
  ami                    = data.aws_ami.amazon_linux_2023.image_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  user_data = <<-EOF
              #!/bin/bash -ex
              exec > /var/log/user_data.log 2>&1

              # Update the system
              sudo dnf update -y

              # Install necessary tools
              sudo dnf install -y curl unzip jq --allowerasing

              # Install Docker
              sudo dnf install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user

              # Set up Kubernetes repo
              cat <<YUM_REPO | sudo tee /etc/yum.repos.d/kubernetes.repo
              [kubernetes]
              name=Kubernetes
              baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el9-\$basearch
              enabled=1
              gpgcheck=1
              repo_gpgcheck=1
              gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
              YUM_REPO

              # Install Kubernetes components
              sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
              sudo systemctl enable kubelet
              sudo systemctl start kubelet

              # Initialize Kubernetes control plane
              # Note: If this is a single-control-plane cluster, it's safe to do directly. 
              sudo kubeadm init --pod-network-cidr=10.244.0.0/16

              # Set up kubeconfig for ec2-user
              mkdir -p /home/ec2-user/.kube
              sudo cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
              sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config

              # Use the admin kubeconfig
              export KUBECONFIG=/etc/kubernetes/admin.conf

              # Wait briefly for the API server to be fully ready
              sleep 60

              # Install the Weave Net CNI (adjust if you prefer another network plugin)
              kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\\n')"

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Upload kubeconfig to S3
              aws s3 cp /etc/kubernetes/admin.conf s3://${aws_s3_bucket.kubeconfig_bucket.bucket_domain_name}/kubeconfig-$(hostname)-$(date +%Y-%m-%d).conf
              EOF

  tags = {
    Name = "ec2_k8s"
  }

  depends_on = [ aws_s3_bucket.kubeconfig_bucket ]
}
