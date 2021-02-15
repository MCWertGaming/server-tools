#!/bin/bash

## back up task for nexus 3

# stop nexus
systemctl stop nexus.service

# manage permissions
chown -R nexus:nexus /opt/nexus_nfs

# create backup
tar -I zstd -cvf /opt/nexus_nfs/nexus-backup.tar.zst /opt/nexus3/sonatype-work/

# update system
yum update -y

# reboot
reboot
