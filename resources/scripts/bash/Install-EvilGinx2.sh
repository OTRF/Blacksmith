#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/C2s-install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# Install Docker and Docker-Compose
./Install-Docker.sh

# *********** Installing Service ***********
git clone https://github.com/kgretzky/evilginx2 /opt/evilginx2 >> $LOGFILE 2>&1
cd /opt/evilginx2 && docker build -t evilginx2 . >> $LOGFILE 2>&1

docker run -d -it -p 53:53/udp -p 80:80 -p 443:443 --name evilginx2 -v /opt/evilginx2/phishlets:/app/phishlets evilginx2 >> $LOGFILE 2>&1