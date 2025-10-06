# Imagine the sh script is executed on a newly setup ec2 ubuntu server

# 1. Update apt packages
# 2. Install docker binaries
# 3. Generate ssl certs
# 4. Generate .httpasswd file
# 6. Create docker images and containers
# 7. Edit /etc/hosts file
# 8. Test the connection

set -e

sudo apt update && sudo apt upgrade -y

echo "Adding and Installing docker packages"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed."
    exit 1
fi

docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}'

echo "Generating ssl certificates for nginx"
mkdir -p ./nginx/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ./nginx/certs/nginx-selfsigned.key \
    -out ./nginx/certs/nginx-selfsigned.crt \
    -subj "/C=IN/ST=NewDelhi/L=NewDelhi/O=DevOps/CN=nginx"

echo "Generating .htpasswd for Basic Authentication"
sudo apt install -y apache2-utils
sudo htpasswd -cb ./nginx/.htpasswd admin password@123

echo "Start docker containers"
docker run -d --name jenkins -p 8080:8080 jenkins/jenkins:jdk21

docker run -d --name grafana -p 3000:3000 grafana/grafana:main-ubuntu

docker run -d --name nginx -p 8080:80 -p 8443:443 \
    -v ./nginx/conf.d:/etc/nginx/conf.d:ro \
    -v ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro \
    -v ./nginx/certs:/etc/nginx/certs:ro \
    nginx:latest

echo "Adding jenkins.local and grafana.local to hosts"
echo "127.0.0.1 jenkins.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts

echo "Setup Complete. Test Connection"

