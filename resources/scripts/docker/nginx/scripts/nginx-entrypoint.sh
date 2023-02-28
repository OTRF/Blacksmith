#!/bin/sh

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

_term() {
  echo "Terminating Nginx Services"
  service nginx stop
  exit 0
}
trap _term SIGTERM

# ************* Creating Certificate ***********
openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/Nginx.key \
    -out /etc/ssl/certs/Nginx.crt \
    -subj "/C=US/ST=VA/L=VA/O=Nginx/OU=Ngnix Nginx/CN=Nginx"

echo "Starting remaining services.."
service nginx restart

echo "Pushing Nginx Logs to console.."
tail -f /var/log/nginx/*.log