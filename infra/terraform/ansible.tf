# Generate Ansible inventory file dynamically
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    instance_ip   = aws_eip.devops.public_ip
    instance_id   = aws_instance.devops.id
    ssh_key_name  = var.ssh_key_name
  })

  depends_on = [aws_eip.devops]
}

# Run Ansible playbook after EC2 is ready
resource "null_resource" "ansible_provisioner" {
  provisioner "remote-exec" {
    inline = [
      "echo 'Wait for SSH to be ready'",
      "while ! command -v ansible-playbook &> /dev/null; do echo 'Waiting for Ansible...'; sleep 10; done",
      "echo 'Ansible is ready'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/${var.ssh_key_name}.pem")
      host        = aws_eip.devops.public_ip
      timeout     = "10m"
    }
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../ansible
      sleep 30
      ansible-playbook \
        -i inventory.ini \
        -e "ansible_user=ubuntu" \
        -e "ansible_ssh_private_key_file=~/.ssh/${var.ssh_key_name}.pem" \
        main.yml \
        --verbose
    EOT

    on_failure = continue
  }

  depends_on = [
    local_file.ansible_inventory,
    aws_instance.devops,
    aws_eip.devops
  ]
}
