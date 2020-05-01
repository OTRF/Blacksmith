#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Removing old docker
if [ -x "$(command -v docker)" ]; then
    echo "Removing docker.."
    apt-get remove -y docker docker-engine docker.io containerd runc
fi

# Installing latest Docker
echo "Installing docker via convenience script.."
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh

# Starting Docker service
while true; do
    if (systemctl --quiet is-active docker.service); then
        echo "Docker is running."
        docker -v
        break
    else
        echo "Docker is not running. Attempting to start it.."
        systemctl enable docker.service
        systemctl start docker.service
        sleep 2
    fi
done

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
wget -O /opt/logstash/scripts/logstash-entrypoint.sh https://raw.githubusercontent.com/OTRF/Azure-Sentinel2Go/master/logstash/scripts/logstash-entrypoint.sh
wget -O /opt/logstash/pipeline/nxlog.conf https://raw.githubusercontent.com/OTRF/Azure-Sentinel2Go/master/logstash/pipeline/nxlog.conf
wget -O /opt/logstash/config/logstash.yml https://raw.githubusercontent.com/OTRF/Azure-Sentinel2Go/master/logstash/config/logstash.yml
wget -O /opt/logstash/docker-compose.yml https://raw.githubusercontent.com/OTRF/Azure-Sentinel2Go/master/logstash/docker-compose.yml

docker-compose -f /opt/logstash/docker-compose.yml up --build -d