#!/bin/bash

## back up task for nexus 3

# stop nexus
systemctl stop nexus.service

# create backup
cd /opt/nexus3/
tar -I zstd -cvf /opt/nexus_nfs/nexus-backup.tar.zst sonatype-work/

# update system
yum update -y

# reboot
reboot
