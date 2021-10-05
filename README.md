# Ubuntu RPi Server
---

## Features
- Ubuntu 20.04.2 LTS or 21.04
- Docker
- Automated Nginx reverse proxy

## Prerequisites
- Raspberry Pi - RPi 4 + 8GB preferred
- MicroSD card - 32GB+ preferred
- Cloudflare and Cloudflare Teams account

## Automated Setup - **UNDER CONSTRUCTION**

Start setup script - `sh ./scripts/setup.sh`

## Manual Setup

### Optional: To boot from a USB drive, update bootloader
1. Using [Raspberry Pi Imager](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card), install the updated bootloader on an SD card - Misc Utility Images > Bootloader > SD Card Boot
1. Plug the SD card into the RPi and boot. Wait for 10+ seconds and ensure green light is blinking indefinitely
1. Turn off RPi and remove SD card

### Install Ubuntu on RPi
1. SD CARD - Using [Raspberry Pi Imager](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card), install Ubuntu:
    - Ensure USB drive is formatted in `FAT32`. You can format the card via the Raspberry Pi Imager.
    - For Long Term Support, flash 20.04.2 LTS (Focal Fossa) 64-bit Server (arm64) on SD card
    - For most current stable version, flash 21.04 (Hirusite Hippo) 64-bit Server (arm64) on SD card
    - Do not enable any advanced or wifi settings at this time.
1. USB DRIVE - Using [Raspberry Pi Imager](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card), install Ubuntu:
    - Ensure USB drive is formatted in `FAT32`. You can format the card via the Raspberry Pi Imager.
    - In order to boot from USB out-of-the-box, flash 21.04 (Hirusite Hippo) 64-bit Server (arm64) on the USB drive.
    - Do not enable any advanced or wifi settings at this time.
1. You may need to clear the Imager cache if writing to the card produces an extraction error
    - macOS - `sudo rm -rf "~/Library/Caches/Raspberry Pi/Imager"`
1. After the imager flashes the OS, open the card/drive from terminal:
    1. To enable SSH add a blank `ssh` file at the root of the SD card
        ```
        cd /Volumes/system-boot
        touch ssh
        ```
    1. Change WiFi settings in `network-config` file (NOTE: the Ubuntu docs for this file have incorrect formatting) - `sudo rm network-config && sudo nano network-config`:
        ```
        network:
          version: 2
          ethernets:
            eth0:
              dhcp4: true
              optional: true

          wifis:
            wlan0:
              dhcp4: true
              optional: true
              access-points:
                "Your SSID":
                  password: "YourSSIDPassword"
        ```
    1. HDMI Display Troubleshooting - For my Sony Bravia 4K TV, I needed to set the TV settings to [Enhanced Format](https://everythingwhat.com/how-do-i-change-the-resolution-on-my-sony-bravia-tv) and reboot the TV. [Additional `config.txt` settings](https://www.retrogamesaddict.com/how-to-fix-a-blank-screen-when-booting-retropie/) - `sudo nano config.txt`:
        ```
        hdmi_safe=1
        ```
        OR
        ```
        hdmi_force_hotplug=1
        hdmi_drive=2
        hdmi_group=1
        hdmi_mode=1
        ```

### Connect to Raspberry Pi on the network
1. Plug in the RPi to the router/switch via ethernet (in case the wifi doesn't work immediately), as well as a keyboard and monitor.
1. Boot the SD card in the RPi. Look for its IP address on the network using `nmap -sn 192.168.1.0/24` - edit for your appropriate subnet.
1. Add entry to your SSH config file
1. SSH into the RPi using `ssh ubuntu@<RPi IP Address>` and password `ubuntu`
1. Change pw when prompted

### [Network troubleshooting](https://askubuntu.com/questions/1324207/problem-with-wireless-networking-for-ubuntu-server-on-a-raspberry-pi-4/1324212#1324212)
1. If you can't connect or find your RPi on the network, plug a keyboard and monitor in and boot it up.
1. Check `sudo nano /etc/netplan/50-cloud-init.yaml` to make sure it matches the `network-config` from above. If not, add to this `.yaml` file matching the above configuration, substituting your credentials where applicable.
1. Enable netplan:
    ```
    sudo systemctl enable wpa_supplicant
    sudo systemctl start wpa_supplicant
    sudo netplan generate
    sudo netplan apply
    sudo reboot
    ```

### Update and install packages on RPi
1. Update packages - `sudo apt-get update && sudo apt-get upgrade -y`
1. Install Git - `sudo apt install git-all -y`
1. Install Git again (in case failed) - `sudo apt install git-all -y`
1. Configure Git credentials:
    ```
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    ```
1. Set Timezone - `sudo timedatectl set-timezone America/Denver`
1. Remove http servers (conflicts with dockerized automated nginx proxy) - `sudo apt-get purge apache2 -y && sudo apt-get purge nginx -y`
1. Clean house - `sudo apt-get autoremove -y`

### Configuration
Be sure to change the arguments in <BRACKETS> to your credentials
1. Add User:
    1. `sudo adduser <USERNAME>`
    1. Add user to sudo group - `sudo usermod -aG sudo <USERNAME>`

1. Set-up SSH credentials:
    1. On local machine, create SSH key pair - `ssh-keygen -f ~/path/to/your/key -t ecdsa -b 521`
    1. Add your public key to the server's authorized_keys file and `~/.ssh/`. It will ask you for a password - `ssh-copy-id -i ~/path/to/your/key <USERNAME>@host`
    1. Correct SSH permissions:
        - `chmod 700 ~/.ssh` - ssh directory
        - `chmod 600 ~/.ssh/id_rsa` - private key
        - `chmod 600 ~/.ssh/authorized_keys` - authorized_keys file
    1. After you have logged in and ensured your key works, remove logging in via password. MAKE SURE TO KEEP A SUDO TAB OPEN ON THE SERVER:
        - `sudo nano /etc/ssh/sshd_config`
        - Change - `PasswordAuthentication yes` to `PasswordAuthentication no`
        - Restart SSH - `sudo systemctl restart ssh`
        - Test SSH w/o password: - `ssh -i /path/to/key user@host`

1. Logout and login with the new user

1. Firewall (ufw) configuration:
    1. Check current firewall status - `sudo ufw status numbered`
    1. Block all incoming - `sudo ufw default deny incoming`
    1. Allow all outgoing - `sudo ufw default allow outgoing`
    1. Allow port 22 - `sudo ufw allow OpenSSH`
    1. Allow port 80 - `sudo ufw allow http`
    1. Allow port 443 - `sudo ufw allow https`
    1. Allow port 2022 - `sudo ufw allow 2022`
    1. Optional: Allow port 8080 - `sudo ufw allow 8080`
    1. Optional: Allow port 5000 - `sudo ufw allow 5000`
    1. Optional: Allow port 5001 - `sudo ufw allow 5001`
    1. Optional: Allow port 3000 - `sudo ufw allow 3000`
    1. Enable the firewall - `sudo ufw enable`

1. Install fail2ban:
    ```
    sudo apt install fail2ban -y
    sudo systemctl enable fail2ban
    ```

1. Install Docker (arm64):
    1. Remove old versions, if installed:
        ```
        sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras
        sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras
        sudo umount /var/lib/docker/
        sudo rm -rf /var/lib/docker /var/run/docker.sock /var/lib/containerd /etc/docker /etc/apparmor.d/docker /usr/bin/docker-compose /usr/local/bin/docker-compose
        sudo groupdel docker
        ```
    1. Install Docker:
        ```
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
        sudo usermod -aG docker $USER
        sudo gpasswd -a $USER docker
        newgrp docker
        sudo su $USER
        ```
    1. Connect Docker and docker-compose services `sudo nano /etc/systemd/network/bridge.network`:
        ```
        [Network]

        IPForward=kernel
        ```
    1. Reinstall docker-ce:
        ```
        sudo systemctl restart systemd-networkd.service
        sudo apt remove docker-ce -y
        sudo apt install docker-ce
        sudo apt install docker-ce -y
        ```

1. Install docker-compose:
    1. Install pip3 and docker-compose:
        ```
        sudo apt install python3-pip -y
        pip3 install docker-compose
        ```
    1. Add dependencies to PATH:
        ```
        export PATH="$HOME/bin:$PATH"
        export PATH="$HOME/.local/bin:$PATH"
        ```
    1. Check if docker-compose installed correctly - `docker-compose --version`

### Optional: Boot from correct USB if multiple are present
After successfully setting up 1 USB:
1. Determine drive names and UUID - `blkid`
1. `sudo nano /boot/firmware/cmdline.txt`
1. Change `root=/dev/whatever` to `root=UUID=#####....` for the desired bootable drive
1. Plug in 2nd USB drive
1. Create mount point directory for 2nd drive - `sudo mkdir /media/usb2`
1. Mount USB2 - `sudo mount /dev/sdb2 /media/usb2` - your device (sdb2) may be different

To grant read/write access to all USB devices:
1. `sudo nano /etc/udev/rules.d/99-perm.rules`:
    ```
    SUBSYSTEM=="usb", OWNER="<NON_ROOT_USER>"
    ```
1. Reboot - `sudo reboot`
1. [More granular device control](https://ramonh.dev/2020/09/22/usb-device-linux-startup/)

### Optional: Make your RPi accessible to the internet
1. [Install Cloudflared](https://dev.to/omarcloud20/a-free-cloudflare-tunnel-running-on-a-raspberry-pi-1jid):
    1. `wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64`
    1. `sudo mv cloudflared /usr/local/bin`
    1. `sudo chmod +x /usr/local/bin/cloudflared`
    1. Authenticate Cloudflared - `cloudflared login`
    1. Copy/paste link generated on the cmd line into a browser and follow instructions.
    1. Create a tunnel - `cloudflared tunnel create <TUNNEL_NAME>`. Note down the UUID somewhere safe, which follows "Created tunnel xxxx with id #######-####-###-#####..."
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
    1. Make config dir if it doesn't exist - `sudo mkdir /etc/cloudflared`
    1. Copy config to service directory - `sudo cp -r ~/.cloudflared/* /etc/cloudflared`

1. Create DNS records (2 options):
    1. CNAME - subdomain - <UUID.cfargotunnel.com>
    1. `cloudflared tunnel route dns <UUID or TUNNEL_NAME> YOUR.DOMAIN.HERE`
    1. Add one for Port 80 and Port 2022

1. Add a Zero Trust policy to Cloudflare Teams:
    1. Access > Applications > Add an application > Self-Hosted:
        - Add name, session duration, subdomain, and application name
    1. Rule:
        - Add rule name, Rule action = Bypass, Include = Everyone
    1. Advanced Settings:
        - Enable automatic cloudflared authentication, Browser rendering = SSH

1. Run cloudflared tunnel (2 options):
    1. With the cmd line - `sudo cloudflared tunnel run <TUNNEL_NAME>` - NOTE: this requires an open terminal tab with the cloudflared tunnel running in order for any end users to access the websites hosted on this server, hence why running as a service is preferred.
    1. (PREFERRED) As a service, in the background - `sudo cloudflared service install`
        - [Troubleshooting issues with service](https://github.com/cloudflare/cloudflared/issues/251) - DOES NOT WORK WITH REMOTE SSH CURRENTLY

1. Optional: [Add remote SSH capability](https://dev.to/blake/creating-securing-a-remote-dev-environment-3558):
    1. Open a new tab on the server. SSH in, if necessary. This ensures the tunnel stays running until you start it as a service.
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
          User $USER
        ```
    1. On remote host - Run the cloudflared tunnel (if not already running or running as a service in the background) - `cloudflared tunnel run <TUNNEL_NAME>`
    1. Run the SSH daemon on the remote host - `cloudflared access ssh --hostname YOUR.DOMAIN.HERE`. This CANNOT be run as a service (tab has to stay open and running to access via SSH)
    1. You should be able to connect via SSH - `ssh YOUR.DOMAIN.HERE`
    1. Add `Remote - SSH` if you use Visual Studio - [Link](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

### Optional: Enable Camera
    1. Plug in USB camera or Raspberry Pi
    1. Add user to `video` group - `sudo usermod -a -G video $USER`
    1. Check if Ubuntu recognizes camera - `dmesg | grep -i "Camera"` or `ls -ltrh /dev/video*`
    1. Install `v4l2` - `sudo apt install v4l2-utils`
    1. Check out more info on camera - `v4l2-ctl --device=/dev/video* --all`
    1. List devices with video data use:
        ```
          for dev in `find /dev -iname 'video*' -printf "%f\n"`
          do
          v4l2-ctl --list-formats --device /dev/$dev | \
            grep -qE '\[[0-9]\]' && \
            echo $dev `cat /sys/class/video4linux/$dev/name`
          done
        ```
    1. Your cameras will have "Video Recording" capability and not "Meta Recording" capability. Although I had 2 cameras plugged in, approx. 10 video devices were shown. My actual cameras were on `/dev/video0` and `/dev/video2`
    1. Add [this repo](https://github.com/miguelgrinberg/flask-video-streaming) to your Docker app

### Install Proxy
1. Stop services using port 80, if running - `sudo service apache2 stop && sudo service nginx stop`
1. Git clone proxy - `git clone https://github.com/avidsapp/arm64-nginx-proxy.git proxy`
1. Start proxy - `cd proxy && docker-compose up -d`
1. Start other applications, but include environment variable `VIRTUAL_HOST: YOUR.DOMAIN.HERE`

## Dockerized applications to add to your server
1. [Docker WordPress](https://github.com/avidsapp/docker-wordpress.git)
1. [Docker Owncloud](https://github.com/avidsapp/docker-owncloud.git)
1. [Docker Uptime Monitor](https://github.com/avidsapp/docker-uptime-monitor.git)
1. [Docker Flask API](https://github.com/avidsapp/docker-flask-api.git)
1. [Docker Flask Webcam](https://github.com/avidsapp/docker-flask-webcam.git)
1. [Docker Flask Socket](https://github.com/avidsapp/docker-flask-react.git)
1. [Docker Flask React Socket](https://github.com/avidsapp/docker-flask-react-socket.git)
1. [Docker Backup](https://github.com/offen/docker-volume-backup)

## ToDo
1. Build script
1. Runtime env variables
1. Switch nginx to traefik
