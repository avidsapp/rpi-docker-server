# Start with sh ./setup.sh

# Load .env variables
export $(grep -v '#.*' .env | xargs)

# Install dependencies and clean house
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install git-all -y
sudo apt install git-all -y
sudo timedatectl set-timezone America/Denver
sudo apt-get purge apache2 -y && sudo apt-get purge nginx -y
sudo apt-get autoremove -y

# Add user
sudo useradd -p $(openssl passwd -1 $PASS) $USERNAME
sudo usermod -aG sudo $USERNAME

# AUTOMATE - SSH CREDENTIALS

# Setup firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH 2022 http https 8080 5000 5001 3000
sudo ufw enable

# Install Docker
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
curl -sSL https://get.docker.com | sh
sudo groupadd docker
sudo gpasswd -a $USERNAME docker

# Install docker-compose
sudo curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install cloudflared
wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared /usr/local/bin
sudo chmod +x /usr/local/bin/cloudflared

############
# AUTOMATE #
############

# # Authorize cloudflared
# cloudflared login
#
# # Create tunnel
# cloudflared tunnel create $TUNNEL_NAME
#
# # Add cloudflared config
# sudo nano ~/.cloudflared/config.yml
#   tunnel: $UUID
#   credentials-file: /etc/cloudflared/$UUID.json
#
#   ingress:
#     - hostname: $DOMAIN1
#       service: http://localhost:80
#     - hostname: $DOMAIN2
#       service: ssh://localhost:2022
#     - service: http_status:404
#
# sudo mkdir /etc/cloudflared
# sudo cp -r ~/.cloudflared/* /etc/cloudflared
#
# # Add DNS
# cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN1
# sudo cloudflared service install

# UNCOMMENT AFTER CLOUDFLARED AUTOMATION COMPLETE

# Install and run proxy
# sudo service apache2 stop && sudo service nginx stop
# git clone https://github.com/avidsapp/arm64-nginx-proxy.git proxy
# cd proxy && sudo docker-compose up -d

# Reboot when complete
sudo reboot
