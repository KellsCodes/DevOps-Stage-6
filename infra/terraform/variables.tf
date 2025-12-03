variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "devops-stage-6-server"
}

variable "ami_filter" {
  description = "AMI filter for Ubuntu 22.04 LTS"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ami_owner" {
  description = "AMI owner (Canonical for Ubuntu)"
  type        = string
  default     = "099720109477"
}

variable "ssh_key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
  default     = "hng13"
  # Created in AWS beforehand
}

variable "ssh_private_key" {
  description = "Private SSH key for connecting to EC2 instances (used in CI/CD)"
  type        = string
  sensitive   = true
  default     = ""
  # Leave empty for local runs (Ansible uses ~/.ssh/hng13.pem)
  # CI/CD provides this via GitHub secrets
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "duckdns_domain" {
  description = "DuckDNS domain name"
  type        = string
  default     = "anyitech.duckdns.org"
}

variable "duckdns_token" {
  description = "DuckDNS token for updating DNS"
  type        = string
  sensitive   = true
  default     = ""
  # Provide via -var or GitHub secrets
}
