#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/PenPot-Install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# Install Docker and Docker-Compose
if [[ ! -f Install-Docker.sh ]]; then
    wget https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/scripts/bash/Install-Docker.sh >> $LOGFILE 2>&1
    chmod +x Install-Docker.sh >> $LOGFILE 2>&1
fi
./Install-Docker.sh >> $LOGFILE 2>&1

# Download PenPot Docker Compose File
if [[ ! -f docker-compose.yaml ]]; then
    wget https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/scripts/docker/penpot/docker-compose.yaml >> $LOGFILE 2>&1
fi
docker compose -p penpot -f docker-compose.yaml up -d >> $LOGFILE 2>&1