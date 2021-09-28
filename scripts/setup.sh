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
sudo useradd -p $(openssl passwd -1 $PASSWORD) $USERNAME
sudo usermod -aG sudo $USERNAME

# AUTOMATE - SSH CREDENTIALS

# Setup firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 2022
sudo ufw allow 8080
sudo ufw allow 5000
sudo ufw allow 5001
sudo ufw allow 3000
sudo ufw enable

# Install fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban

# Ensure other Docker versions aren't installed
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras
sudo umount /var/lib/docker/
sudo rm -rf /var/lib/docker /var/run/docker.sock /var/lib/containerd /etc/docker /etc/apparmor.d/docker /usr/bin/docker-compose /usr/local/bin/docker-compose
sudo groupdel docker

# Install Docker
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
    "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo groupadd docker
sudo usermod -aG docker $USERNAME
sudo gpasswd -a $USERNAME docker
newgrp docker
sudo su $USERNAME

############
# AUTOMATE #
############

# sudo nano /etc/systemd/network/bridge.network
# [Network]
#
# IPFoward=kernel

# Reinstall docker-ce
sudo systemctl restart systemd-networkd.service
sudo apt remove docker-ce -y
sudo apt install docker-ce
sudo apt install docker-ce -y

# Install docker-compose
sudo apt install python3-pip -y
pip3 install docker-compose
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

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
