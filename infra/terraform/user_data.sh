#!/bin/bash
set -e

# Log output
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "=== Starting DevOps Stage 6 Setup ==="
echo "Timestamp: $(date)"

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose (standalone)
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
echo "Starting Docker..."
systemctl start docker
systemctl enable docker

# Install Ansible
echo "Installing Ansible..."
apt-get install -y ansible

# Verify Ansible installation
ansible --version

# Create app directory
echo "Creating app directory..."
mkdir -p /home/ubuntu/apps
cd /home/ubuntu/apps

# Clone the DevOps repository
echo "Cloning DevOps Stage 6 repository..."
git clone https://github.com/KellsCodes/DevOps-Stage-6.git DevOps-Stage-6 || echo "Repository clone failed or already exists"

cd /home/ubuntu/apps/DevOps-Stage-6 || exit 1

# Pull latest changes
echo "Pulling latest changes..."
git pull || echo "Git pull failed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << 'EOF'
# frontend:
PORT=8080
AUTH_API_ADDRESS=http://auth-api:8081
TODOS_API_ADDRESS=http://todos-api:8082

# auth-api:
AUTH_API_PORT=8081
JWT_SECRET=myfancysecret
USERS_API_ADDRESS=http://users-api:8083

# todos-api:
JWT_SECRET=myfancysecret
REDIS_HOST=redis-queue
REDIS_PORT=6379
REDIS_CHANNEL=log_channel

# users-api:
SERVER_PORT=8083
JWT_SECRET=myfancysecret

# log-message-processor:
REDIS_HOST=redis-queue
REDIS_PORT=6379
REDIS_CHANNEL=log_channel
EOF
fi

# Start Docker Compose
echo "Starting Docker Compose services..."
docker compose down || true
docker compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Update DuckDNS (in case the provisioner didn't work)
echo "Updating DuckDNS..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
curl -X GET "https://www.duckdns.org/update?domains=${duckdns_domain}&token=${duckdns_token}&ip=$PUBLIC_IP" || echo "DuckDNS update attempt completed"

echo "=== DevOps Stage 6 Setup Complete ==="
echo "Public IP: $PUBLIC_IP"
echo "Domain: ${duckdns_domain}"
echo "Access at: https://${duckdns_domain}"
