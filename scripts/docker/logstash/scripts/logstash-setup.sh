#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -b         bootstrap_server kafka-like"
    echo "   -c         EventHub config parameters"
    echo "   -n         EventHub name"
    echo
    echo "Examples:"
    echo " $0 -b <eventhubNamespace>.servicebus.windows.net:9093 -c \"org.apache.kafka.common.security.plain.PlainLoginModule required username=$ConnectionString password='Endpoint=sb://<alias or name of the event hub namespace>.servicebus.windows.net/;SharedAccessKeyName=<name of the Policy>;SharedAccessKey=<secret key from the connection string>';\" -n <event hub name>"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts b:c:n:h option
do
    case "${option}"
    in
        b) BOOTSTRAP_SERVER=$OPTARG;;
        c) SASL_JAAS_CONFIG=$OPTARG;;
        n) EVENTHUB_NAME=$OPTARG;;
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

echo "Downloading logstash files locally to be mounted to docker container"
wget -O /opt/logstash/scripts/logstash-entrypoint.sh https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/scripts/docker/logstash/scripts/logstash-entrypoint.sh
wget -O /opt/logstash/pipeline/eventhub.conf https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/scripts/docker/logstash/pipeline/eventhub.conf
wget -O /opt/logstash/config/logstash.yml https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/scripts/docker/logstash/config/logstash.yml
wget -O /opt/logstash/docker-compose.yml https://raw.githubusercontent.com/hunters-forge/Blacksmith/azure/scripts/docker/logstash/docker-compose.yml

chown -R logstash:logstash /opt/logstash/*
chmod +x /opt/logstash/scripts/logstash-entrypoint.sh

export BOOTSTRAP_SERVER=$BOOTSTRAP_SERVERS
export SASL_JAAS_CONFIG=$SASL_JAAS_CONFIG
export EVENTHUB_NAME$EVENTHUB_NAME

docker-compose -f /opt/logstash/docker-compose.yml up --build -d