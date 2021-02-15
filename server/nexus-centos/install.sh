#!/bin/bash

## nexus install script for centos 7

# set static ip
sudo nmcli con mod "eth0" ipv4.addresses "10.10.11.12/24" ipv4.gateway "10.10.11.1" ipv4.dns "192.168.1.10,192.168.1.99" ipv4.dns-search "l-its.de" ipv4.method "manual"

# set hostname
hostnamectl set-hostname nexus
# update system and install required packages
yum update -y
yum -y install java-1.8.0-openjdk-headless wget

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
useradd --system --no-create-home nexus
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
curl <script> > /opt/scripts/nexus-updater.sh
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
WantedBy=multi-user.target"