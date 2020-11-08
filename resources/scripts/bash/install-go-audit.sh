#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Set environment variables.
export GOROOT=/usr/local
export GOPATH=/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export NVM_DIR=/usr/local/nvm

mkdir -p $NVM_DIR

apt-get update -y
apt-get install -y build-essential git jq auditd
# Download Latest Go
GO_VERSION=$(curl https://golang.org/VERSION?m=text)
curl https://storage.googleapis.com/golang/${GO_VERSION}.linux-amd64.tar.gz | tar xvzf - -C /usr/local --strip-components=1
# Install pre-requisities for go-audit
go get -u github.com/kardianos/govendor
cd go/src/
# Clone go-audit project
git clone https://github.com/slackhq/go-audit.git
cd go-audit
# Build binary
go build
# Copy go-audit yaml
cp go-audit.yaml.example go-audit.yaml
# Copy go-audit binary
cp go-audit /usr/local/bin/
# Download nvm
NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Installing latest npm LTS
nvm install --lts
npm install -g https://github.com/nbrownus/streamstash#2.0
# Set Note path
export NODE_PATH="$(npm root -g)"
# Stop Auditd Service
service auditd stop