# Generate Ansible inventory file dynamically
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content = templatefile("${path.module}/inventory.tpl", {
    instance_ip  = aws_eip.devops.public_ip
    instance_id  = aws_instance.devops.id
    ssh_key_name = var.ssh_key_name
  })

  depends_on = [aws_eip.devops]
}

# Run Ansible playbook after EC2 is ready
resource "null_resource" "ansible_provisioner" {

  # Only local execution (no remote Ansible needed)
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # --- Create temporary SSH key ---
      TMP_KEY_FILE=$(mktemp)
      echo "${var.ssh_private_key}" > $TMP_KEY_FILE
      chmod 600 $TMP_KEY_FILE

      cd ${path.module}/../ansible

      # --- Remote log file ---
      REMOTE_LOG="/home/ubuntu/ansible_run.log"
      echo "=== Starting Ansible run at $(date) ===" | ssh -o StrictHostKeyChecking=no -i $TMP_KEY_FILE ubuntu@${aws_eip.devops.public_ip} 'tee -a $REMOTE_LOG'

      # --- Run Ansible playbook locally, log to remote and local ---
      ansible-playbook -i inventory.ini main.yml \
        -e "ansible_user=ubuntu" \
        -e "ansible_ssh_private_key_file=$TMP_KEY_FILE" \
        --verbose | tee /tmp/ansible_local.log

      # --- Copy local log to remote for permanent record ---
      scp -o StrictHostKeyChecking=no -i $TMP_KEY_FILE /tmp/ansible_local.log ubuntu@${aws_eip.devops.public_ip}:$REMOTE_LOG

      rm -f $TMP_KEY_FILE
    EOT

    # Continue Terraform execution even if Ansible fails (optional)
    on_failure = continue
  }

  # Dependencies
  depends_on = [
    local_file.ansible_inventory,
    aws_instance.devops,
    aws_eip.devops
  ]
}
