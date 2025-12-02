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
  # Optional: Verify SSH is reachable and Ansible is installed (remote side)
  provisioner "remote-exec" {
    inline = [
      "echo 'Checking SSH connectivity and Ansible installation...'",
      "while ! command -v ansible-playbook &> /dev/null; do echo 'Waiting for Ansible to be installed...'; sleep 10; done",
      "echo 'Ansible is ready on remote host.'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = aws_eip.devops.public_ip
      timeout     = "10m"
    }
  }

  # Run the Ansible playbook locally, but log output both locally and on remote server
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      TMP_KEY_FILE=$(mktemp)
      echo "${var.ssh_private_key}" > $TMP_KEY_FILE
      chmod 600 $TMP_KEY_FILE

      cd ${path.module}/../ansible

      # Create a remote log file on the EC2 instance
      REMOTE_LOG="/home/ubuntu/ansible_run.log"
      echo "Starting Ansible run at $(date)" | ssh -i $TMP_KEY_FILE ubuntu@${aws_eip.devops.public_ip} 'tee -a $REMOTE_LOG'

      # Run Ansible playbook with SSH key, stream output to remote log and local stdout
      ansible-playbook -i inventory.ini main.yml \
        -e "ansible_user=ubuntu" \
        -e "ansible_ssh_private_key_file=$TMP_KEY_FILE" \
        --verbose | tee /tmp/ansible_local.log

      # Copy local log to remote server for permanent record
      scp -i $TMP_KEY_FILE /tmp/ansible_local.log ubuntu@${aws_eip.devops.public_ip}:$REMOTE_LOG

      rm -f $TMP_KEY_FILE
    EOT

    on_failure = continue
  }

  depends_on = [
    local_file.ansible_inventory,
    aws_instance.devops,
    aws_eip.devops
  ]
}
