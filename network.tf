resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "k8s_vpc"
  }
}

# Public Subnet (for NAT Gateway and instances that need public IPs)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s_public_subnet"
  }
}

# Private Subnet (no public IPs, NAT gateway will provide outbound access)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = false

  tags = {
    Name = "k8s_private_subnet"
  }
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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Internet Gateway for public outbound internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s_igw"
  }
}

# Public Route Table: Routes 0.0.0.0/0 via the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "k8s_public_rt"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "k8s_nat_eip"
  }
}

# NAT Gateway in the public subnet
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "k8s_natgw"
  }
}

# Private Route Table: Routes 0.0.0.0/0 via the NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "k8s_private_rt"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}