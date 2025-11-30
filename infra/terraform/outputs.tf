output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.devops.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.devops.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.devops.private_ip
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.devops.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "duckdns_domain" {
  description = "DuckDNS domain"
  value       = var.duckdns_domain
}

output "application_url" {
  description = "URL to access the application"
  value       = "https://${var.duckdns_domain}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/${var.ssh_key_name}.pem ubuntu@${aws_eip.devops.public_ip}"
}
