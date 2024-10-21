resource "aws_instance" "ec2_k8s" {
  ami           = data.aws_ami.amazon_linux_2023
  instance_type = "t2.micro"

  tags = {
    Name = "ec2_k8s"
  }
}