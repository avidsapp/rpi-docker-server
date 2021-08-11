# Ubuntu RPi Server

## Features
- Ubuntu 20.04.2 LTS (Focal Fossa)
- Docker
- Automated Nginx reverse proxy

## Prerequisites
- Raspberry Pi - Rpi 4 + 8GB preferred
- MicroSD card - 32GB+ preferred
- Cloudflare and Cloudflare Teams account

## Setup

### Install Ubuntu on RPi
1. Using [Raspberry Pi Imager](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card), install Ubuntu 20.04.2 LTS (Focal Fossa) 64-bit Server on flash SD. Do not enable any advanced or wifi settings at this time.
1. After the imager flashes the card, open the SD card from the file explorer on your computer:
    1. To enable SSH add a blank `ssh` file at the root of the SD card
        ```
        cd /Volumes/system-boot
        touch ssh
        ```
    1. Change WiFi settings in `network-config` file (NOTE: the Ubuntu docs for this file has incorrect formatting):
        ```
        network:
          version: 2
          ethernets:
            eth0:
              dhcp4: true
              optional: trueubuntu

          wifis:
            wlan0:
              dhcp4: true
              optional: true
              access-points:
                "Your SSID":
                  password: "YourSSIDPassword"
        ```
          - Note: the wifi config requires a reboot before it will actually connect

### Connect to Raspberry Pi on the network
1. Plug in the RPi to the router/switch via ethernet (in case the wifi doesn't work immediately), as well as a keyboard and monitor.
1. Boot the SD card in the RPi. Look for its IP address on the network using `nmap -sn 192.168.1.0/24` - edit for your appropriate subnet.
1. SSH into the RPi using `ssh ubuntu@<RPi IP Address>` and password `ubuntu`
1. Change pw when promtped

### [Network troubleshooting](https://askubuntu.com/questions/1324207/problem-with-wireless-networking-for-ubuntu-server-on-a-raspberry-pi-4/1324212#1324212)
- Raspberry Pi Imager's Advanced Options doesn't work with Ubuntu 20
- If you can't access SSH later, on the pi via keyboard/monitor, try:
  ```
  sudo apt install openssh-server
  sudo service ssh enable
  sudo service ssh start
  ```

### Update and install packages on RPi
1. Update packages - `sudo apt-get update && sudo apt-get upgrade -y`
1. Install Git - `sudo apt install git-all -y`
1. Set Timezone - `sudo timedatectl set-timezone America/Denver`
1. Add User:
    1. `sudo adduser <USER_NAME>`
    1. Add user to sudo group - `sudo usermod -aG sudo <USER_NAME>`
1. Set-up SSH credentials:
    1. On local machine, create SSH key pair - `ssh-keygen -f ~/path/to/your/key -t ecdsa -b 521`
    1. Add your public key to the server's authorized_keys file and `~/.ssh/`. It will ask you for a password - `ssh-copy-id -i ~/path/to/your/key user@host`
    1. Correct SSH permissions:
        - `chmod 700 ~/.ssh`
        - `chmod 600 ~/.ssh/authorized_keys`
    1. After you have logged in and ensured your key works, remove logging in via password. MAKE SURE TO KEEP A SUDO TAB OPEN ON THE SERVER:
        - `sudo nano /etc/ssh/sshd_config`
        - Change - `PasswordAuthentication yes` to `PasswordAuthentication no`
        - Restart SSH - `sudo systemctl restart ssh`
        - Test SSH w/o password: - `ssh -i /path/to/key user@host`
1. Firewall configuration:
    1. Check current firewall status - `sudo ufw status numbered`
    1. Block all incoming - `sudo ufw default deny incoming`
    1. Allow all outgoing - `sudo ufw default allow outgoing`
    1. Allow port 22 - `sudo ufw allow OpenSSH`
    1. Allow port 80 - `sudo ufw allow http`
    1. Allow port 443 - `sudo ufw allow https`
    1. Optional: Allow port 5000 - `sudo ufw allow 5000`
    1. Optional: Allow port 3000 - `sudo ufw allow 3000`
    1. Enable the firewall - `sudo ufw enable`
1. Install Docker and docker-compose:
    1. `sudo apt install docker.io`
    1. Enter the user password if prompted.

### Make your RPi accessible to the internet
1. [Install Cloudflared Daemon](https://dev.to/omarcloud20/a-free-cloudflare-tunnel-running-on-a-raspberry-pi-1jid):
    1. `wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64`
    1. `sudo mv cloudflared /usr/local/bin`
    1. `sudo chmod +x /usr/local/bin/cloudflared`
    1. Authenticate Cloudflared - `cloudflared login`
    1. Copy/paste link generated on the cmd line into a browser and follow instructions.
    1. Create a tunnel - `cloudflared tunnel create <TUNNEL_NAME>`
    1. Make config dir if it doesn't exist - `sudo mkdir /etc/cloudflared`
    1. Configure tunnel -  `sudo nano ~/.cloudflared/config.yml`:
        ```
        tunnel: <UUID>
        credentials-file: /etc/cloudflared/<UUID>.json

        ingress:
          - hostname: your.domain1.com
            service: http://localhost:80
          - hostname: your.domain2.com
            service: ssh://localhost:2022
          - service: http_status:404
        ```
1. [Add remote SSH capability](https://dev.to/blake/creating-securing-a-remote-dev-environment-3558):
    1. Add port 2022 as additional SSH port - `sudo nano /etc/ssh/sshd_config`:
    1. Uncomment and add the following lines:
        ```
        Port 22
        Port 2022
        ```
    1. Restart sshd daemon - `sudo systemctl restart sshd`
    1. On local machine - `sudo cloudflared access ssh-config --hostname YOUR.DOMAIN.HERE`
    1. Add the output to `~/.ssh/config` (SSH config file location):
        ```
        Host YOUR.DOMAIN.HERE
          ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
          User <USER_NAME>
        ```
    1. Run the cloudflared tunnel - `cloudflared tunnel run <TUNNEL_NAME>`
    1. Run the SSH daemon on the remote host - `cloudflared access ssh --hostname YOUR.DOMAIN.HERE`
    1. You should be able to connect via SSH - `ssh YOUR.DOMAIN.HERE`
    1. Add `Remote - SSH` if you use Visual Studio - [Link](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
1. Copy config to service directory - `sudo cp -r ~/.cloudflared/* /etc/cloudflared/config.yml`
1. Create DNS records (2 options):
    1. CNAME - subdomain - <UUID.cfargotunnel.com>
    1. `cloudflared tunnel route dns <UUID or TUNNEL_NAME> YOUR.DOMAIN.HERE`
    1. Add one for Port 80 and Port 2022
1. Add a Zero Trust policy to Cloudflare Teams:
    1. Access > Applications > Self-Hosted:
        - Add name, session duration, subdomain, and application name
    1. Rule:
        - Add rule name, Rule action = Bypass, Include = Everyone
    1. Advanced Settings:
        - Enable automatic cloudflared authentication, Browser rendering = SSH
1. Run cloudflared as a service - `sudo cloudflared service install`
    - [Troubleshooting issues with service](https://github.com/cloudflare/cloudflared/issues/251) - DOES NOT WORK WITH REMOTE SSH CURRENTLY

### Install Proxy
1. Stop services using port 80 - `sudo service apache2 stop && sudo service nginx stop`
1. Git clone proxy - `git clone https://github.com/avidsapp/arm64-nginx-proxy.git proxy`
1. Start proxy - `cd proxy && sudo docker-compose up -d`
1. Start other applications, but include environment variable `VIRTUAL_HOST: YOUR.DOMAIN.HERE`

## Dockerized applications to add to your server
1. [Docker WordPress](https://github.com/avidsapp/docker-wordpress.git)
1. [Docker Flask API](https://github.com/avidsapp/docker-flask-api.git)
1. [Docker Flask Socket](https://github.com/avidsapp/docker-flask-react.git)
1. [Docker Flask React Socket](https://github.com/avidsapp/docker-flask-react-socket.git)

## ToDo
1. Build script
1. Runtime env variables
