# Start with source ./setup.sh

# Update server
sudo apt-get update && sudo apt-get upgrade -y

# Install git
sudo apt install git-all

# Set server timezone
sudo timedatectl set-timezone America/Denver

# Add username
# sudo adduser <USER_NAME>
# sudo usermod -aG sudo <USER_NAME>
