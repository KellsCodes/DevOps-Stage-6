[devops_servers]
devops_server ansible_host=${instance_ip} ansible_user=ubuntu

[devops_servers:vars]
ansible_ssh_private_key_file=~/.ssh/${ssh_key_name}.pem
instance_id=${instance_id}
