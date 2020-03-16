#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -n         EventHub Namespace"
    echo "   -c         EventHub Connection String Primary"
    echo "   -e         EventHub name"
    echo "   -u         Local user to update files ownership"
    echo
    echo "Examples:"
    echo " $0 -n <eventhubNamespace> -c <Endpoint=sb://xxxxx> -e <event hub name>"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts :n:c:e:u:h option
do
    case "${option}"
    in
        n) EVENTHUB_NAMESPACE=$OPTARG;;
        c) EVENTHUB_CONNECTIONSTRING=$OPTARG;;
        e) EVENTHUB_NAME=$OPTARG;;
        u) LOCAL_USER=$OPTARG;;
        h) usage;;
        \?) usage;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "No options specified"
    usage
fi

# ****** Installing latest docker compose
if [ -x "$(command -v docker-compose)" ]; then
    echo "removing docker-compose.."
    rm $(which docker-compose)
fi

echo "Installing docker-compose.."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "creating local logstash folders"
mkdir -p /opt/logstash/scripts
mkdir -p /opt/logstash/pipeline
mkdir -p /opt/logstash/config
mkdir -p /opt/logstash/outputs

echo "Downloading logstash files locally to be mounted to docker container"
wget -O /opt/logstash/scripts/logstash-entrypoint.sh https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Mordor/logstash/scripts/logstash-entrypoint.sh
wget -O /opt/logstash/pipeline/eventhub.conf https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Mordor/logstash/pipeline/eventhub.conf
wget -O /opt/logstash/config/logstash.yml https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Mordor/logstash/config/logstash.yml
wget -O /opt/logstash/docker-compose.yml https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Mordor/logstash/docker-compose.yml
wget -O /opt/logstash/outputs/kafka.rb https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/templates/azure/Mordor/logstash/kafka.rb

chown -R $LOCAL_USER:$LOCAL_USER /opt/logstash/*
chmod +x /opt/logstash/scripts/logstash-entrypoint.sh

export BOOTSTRAP_SERVERS=$EVENTHUB_NAMESPACE.servicebus.windows.net:9093
export SASL_JAAS_CONFIG="org.apache.kafka.common.security.plain.PlainLoginModule required username=\$ConnectionString password='$EVENTHUB_CONNECTIONSTRING';"
export EVENTHUB_NAME=$EVENTHUB_NAME

docker-compose -f /opt/logstash/docker-compose.yml up --build -d