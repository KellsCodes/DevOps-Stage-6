# VPC - Virtual Private Cloud (isolated network)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops-vpc"
  }
}

# Internet Gateway - allows traffic in/out of VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-igw"
  }
}

# Public Subnet - where EC2 will live
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet"
  }
}

# Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table - directs traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "devops-public-rt"
  }
}

# Route Table Association - connects subnet to route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group - firewall rules
resource "aws_security_group" "devops" {
  name        = "devops-security-group"
  description = "Security group for DevOps Stage 6 application"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Allow SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "Allow SSH from specified CIDR"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "devops-sg"
  }
}

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User Data Script - runs on EC2 startup
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    duckdns_domain = var.duckdns_domain
    duckdns_token  = var.duckdns_token
  }))
}

# EC2 Instance
resource "aws_instance" "devops" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.devops.id]
  
  user_data = local.user_data

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # Ensure new instance is created before old one is destroyed
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.instance_name
  }

  depends_on = [aws_internet_gateway.main]
}

# Elastic IP - static public IP for EC2
resource "aws_eip" "devops" {
  instance = aws_instance.devops.id
  domain   = "vpc"

  tags = {
    Name = "devops-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Store the public IP in a file for later use
resource "local_file" "instance_ip" {
  filename = "${path.module}/instance_ip.txt"
  content  = aws_eip.devops.public_ip
}

# Update DuckDNS with the new IP
resource "null_resource" "update_duckdns" {
  provisioner "local-exec" {
    command = "curl -X GET 'https://www.duckdns.org/update?domains=${var.duckdns_domain}&token=${var.duckdns_token}&ip=${aws_eip.devops.public_ip}' || true"
  }

  depends_on = [aws_eip.devops]
}
