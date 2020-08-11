#!/usr/bin/env bash

#cleanup

# update
dnf update -y

# install docker
#dnf install -y yum-utils
#yum-config-manager \
#    --add-repo \
#    https://download.docker.com/linux/centos/docker-ce.repo
#dnf install docker-ce docker-ce-cli containerd.io
#systemctl enable docker

# install podman
#dnf install podman
#systemctl enable podman

# install presiquies
dnf install -y curl

#create directories
mkdir /work
mkdir /work/repos
mkdir /work/logs

# download services
curl -s https://raw.githubusercontent.com/MCWertGaming/server-tools/master/install/services/velocity.service > /etc/systemd/system/velocity.service

# enable them
systemctl enable velocity.service

# set firewall rules
firewall-cmd --add-port=9901/tcp --permanent

# finish
reboot
