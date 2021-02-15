#!/bin/bash

# update the system
yum update -y

## update nexus
# download release
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz -O /opt/nexus.tar.gz
# unpack
cd /opt
tar -xvzf nexus.tar.gz
rm -f nexus.tar.gz
# remove old release
rm -rf /opt/nexus3/*
# move new release
mkdir nexus3/
mv nexus-*/ nexus3/nexus
mv sonatype-work/ nexus3/sonatype-work/
# setup nexus config
echo 'run_as_user="nexus"' > /opt/nexus3/nexus/bin/nexus.rc
sed -i 's/application-host=0.0.0.0/application-host=127.0.0.1/g' /opt/nexus3/nexus/etc/nexus-default.properties
# manage filesystem permissions
chown -R nexus:nexus /opt/nexus3/nexus
chown -R nexus:nexus /opt/nexus3/sonatype-work/

# start nexus
systemctl start nexus.service

# done!
