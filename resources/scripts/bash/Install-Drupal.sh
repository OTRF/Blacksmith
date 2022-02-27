#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/Drupal-Install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** Script Menu ***************
usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -v         run a specific Drupal version"
    echo "   -h         help menu"
    echo
    echo "Examples:"
    echo " $0 -v 8.6.5-debian-9-r14"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts v:h option
do
    case "${option}"
    in
        v) RUN_DRUPAL=$OPTARG;;
        h) usage;;
        \?) usage;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "$ERROR_TAG No options specified"
    usage
fi

# Install Docker and Docker-Compose
if [[ ! -f Install-Docker.sh ]]; then
    wget https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/scripts/bash/Install-Docker.sh >> $LOGFILE 2>&1
    chmod +x Install-Docker.sh >> $LOGFILE 2>&1
fi
./Install-Docker.sh >> $LOGFILE 2>&1

# Check what branch to download
if [[ $RUN_DRUPAL == "latest" ]]; then
    git clone https://github.com/bitnami/bitnami-docker-drupal /opt/bitnami-docker-drupal >> $LOGFILE 2>&1 
else
    git clone --branch $RUN_DRUPAL https://github.com/bitnami/bitnami-docker-drupal /opt/bitnami-docker-drupal >> $LOGFILE 2>&1
    # Update docker-compose.yml file to download the right docker image tag
    sed -i -E "s|image: 'bitnami\/drupal\:.*|image: \'bitnami\/drupal\:$RUN_DRUPAL\'|g" /opt/bitnami-docker-drupal/docker-compose.yml >> $LOGFILE 2>&1
fi

# Run docker containers in the background
cd /opt/bitnami-docker-drupal && docker-compose -f docker-compose.yml up -d >> $LOGFILE 2>&1

## Create SSH Tunnel
# ssh -L 80:127.0.0.1:80 <user>@<VM-IP-Address>