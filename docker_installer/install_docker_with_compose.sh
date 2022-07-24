#!/bin/bash

# Copy the complete Folder which contains this File on your Host, VM or Container....


# Check for root
#
if [ "$(id -u)" != "0" ]
then
        echo "ERROR: This script has to be run as root!"
        exit 1
fi

cd "$(dirname -- "$0")"
pwd

apt install curl

echo "Installing Docker......"
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
