#!/bin/bash

## nexus install script for centos 7

# exit on errors
set -e

# set static ip
sudo nmcli con mod "eth0" ipv4.addresses "10.10.11.12/24" ipv4.gateway "10.10.11.1" ipv4.dns "192.168.1.10,192.168.1.99" ipv4.dns-search "l-its.de" ipv4.method "manual"

# set hostname
hostnamectl set-hostname nexus
# update system and install required packages
yum update -y
yum -y install java-1.8.0-openjdk-headless wget yum-cron epel-release nfs-utils
yum install -y nginx zstd

## install nexus
# download release
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz -O /opt/nexus.tar.gz
# unpack and move
cd /opt
tar -xvzf nexus.tar.gz
rm -f nexus.tar.gz
mkdir nexus3/
mv nexus-*/ nexus3/nexus
mv sonatype-work/ nexus3/sonatype-work/
# create nexus user
useradd --system --create-home nexus
# setup nexus config
echo 'run_as_user="nexus"' > /opt/nexus3/nexus/bin/nexus.rc
sed -i 's/application-host=0.0.0.0/application-host=127.0.0.1/g' /opt/nexus3/nexus/etc/nexus-default.properties
# manage filesystem permissions
chown -R nexus:nexus /opt/nexus3/nexus
chown -R nexus:nexus /opt/nexus3/sonatype-work/
# set nofile limit for nexus user (required for nexus to operate)
echo "nexus - nofile 65536" >> /etc/security/limits.conf
# get updater sctipt
mkdir /opt/scripts
curl https://raw.githubusercontent.com/MCWertGaming/server-tools/master/server/nexus-centos/updater.sh > /opt/scripts/nexus-updater.sh
chmod +x /opt/scripts/nexus-updater.sh

# create updater service
echo "[Unit]
Description=Update nexus3
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/scripts/nexus-updater.sh

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nexus-updater.service

# create system service
echo "[Unit]
Description=Nexus Service
After=syslog.target network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus3/nexus/bin/nexus start
ExecStop=/opt/nexus3/nexus/bin/nexus stop
User=nexus
Group=nexus
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nexus.service

# reload systemd service configurations
systemctl daemon-reload
# enable updater service
systemctl enable nexus-updater.service
# NOTE: nexus.service gets started after nexus-updater is done

## setup NginX
# enable it
systemctl enable nginx
# place certificate
cd /etc/nginx
# wget <url to cert> > /etc/nginx/cert.crt
# wget <url to key> > /etc/nginx/cert.key
# or use selfsigned certificate
mkdir /etc/nginx/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/private/cert.key -out /etc/nginx/private/cert.crt

# get config file
curl https://raw.githubusercontent.com/MCWertGaming/server-tools/master/server/nexus-centos/nginx.conf > /etc/nginx/nginx.conf

# allow https in firewall
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
# reload firewalld
firewall-cmd --reload
# set selinx policy for nginx
setsebool -P httpd_can_network_connect 1

# setup automatic package updates
systemctl enable yum-cron
# only install security updates
sed -i 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf

# get backup script
curl https://raw.githubusercontent.com/MCWertGaming/server-tools/master/server/nexus-centos/backup-task.sh > /opt/scripts/backup-task.sh
chmod +x /opt/scripts/backup-task.sh

# create cron job to backup, update and reboot on every monday at 2 am
echo "0 2 * * mon root /opt/scripts/backup-task.sh" > /opt/scripts/cron-reboot.job
crontab /opt/scripts/cron-reboot.job

# mount nfs share for back-ups
mkdir /opt/nexus_nfs
echo "10.10.11.5:/mnt/nfs_share/nexus-backup /opt/nexus_nfs  nfs defaults 0 0" >> /etc/fstab

# reboot to finish installation
reboot
