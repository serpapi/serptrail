#!/usr/bin/env bash
set -e
# Provide these variables to use as a standalone script
USER=${USER}
NAME=${NAME}
# AUTHKEY=${AUTHKEY}

echo "Configuring the system $NAME for user $USER"

# Do a system update
apt update;
DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install essential packages
apt install -y docker.io curl unattended-upgrades fail2ban

# Set up unattented updates
echo -e "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\n" > /etc/apt/apt.conf.d/20auto-upgrades
/etc/init.d/unattended-upgrades restart

# Set up Tailscale
# curl -fsSL https://tailscale.com/install.sh | sh
# Add --advertise-tags=tag:production for more robust setup (requires defining tags access policy)
# tailscale up --hostname=$NAME --authkey=$AUTHKEY

# Install fail2ban
systemctl start fail2ban.service
systemctl enable fail2ban.service

# Configure firewall
ufw logging on;
ufw default deny incoming;
ufw default allow outgoing;

ufw allow 80;
ufw allow 443;
ufw allow 22;

ufw allow from 10.0.0.0/16 to any port 3000;
ufw allow from 10.0.0.0/16 to any port 3100;
ufw allow from 10.0.0.0/16 to any port 3306;
ufw allow from 10.0.0.0/16 to any port 5432;
ufw allow from 10.0.0.0/16 to any port 6379;
ufw allow from 10.0.0.0/16 to any port 9090;
ufw allow from 10.0.0.0/16 to any port 9100;

ufw --force enable;
systemctl restart ufw.service

# Prepare storage
# mkdir -p /storage;
# chmod 700 /storage;
# chown 1000:1000 /storage;

# Add swap space
fallocate -l 2GB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "\\n/swapfile swap swap defaults 0 0\\n" >> /etc/fstab
sysctl vm.swappiness=20;
echo "\\nvm.swappiness=20\\n" >> /etc/sysctl.conf

# Add non-root user
useradd --create-home $USER
usermod -s /bin/bash $USER
su - $USER -c 'mkdir -p ~/.ssh'
su - $USER -c 'touch ~/.ssh/authorized_keys'
cat /root/.ssh/authorized_keys >> /home/$USER/.ssh/authorized_keys
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/$USER
chmod 0440 /etc/sudoers.d/$USER
visudo -c -f /etc/sudoers.d/$USER
usermod -aG docker $USER

# Allow longer connections
sed -i 's@#ClientAliveInterval 0@ClientAliveInterval 60@g' /etc/ssh/sshd_config
sed -i 's@#ClientAliveCountMax 3@ClientAliveCountMax 10@g' /etc/ssh/sshd_config

# Disable root access
sed -i 's@PasswordAuthentication yes@PasswordAuthentication no@g' /etc/ssh/sshd_config
sed -i 's@PermitRootLogin yes@PermitRootLogin no@g' /etc/ssh/sshd_config

systemctl restart ssh.service
