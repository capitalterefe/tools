#!/bin/bash

number_of_runners=$1

# Define path to create the directories
path="/tmp"

# Create the network for the selenium grid
network_prefix=$(date +%N | sha256sum | base64 | head -c 8)
network_name="ap$network_prefix"
echo "$network_name"

# docker network create -d bridge --subnet $network/$netmask --gateway $gateway $network_name
# docker network ls
# docker network inspect $network_name

# Create directory for grid
cd $path
mkdir $network_name

# Generate docker-compose.yml
cd $network_name
echo "version: '2'
networks:
 docnet:
    external: true

services:
 selenium-hub-$network_prefix:
        image: capitalt/selenium-hub:3.6.0
        environment:
         - GRID_BROWSER_TIMEOUT=60000
         - GRID_TIMEOUT=60000
         - GRID_MAX_SESSION=50
         - GRID_MAX_INSTANCES=3
         - GRID_CLEAN_UP_CYCLE=60000
         - GRID_UNREGISTER_IF_STILL_DOWN_AFTER=180000
         - GRID_NEW_SESSION_WAIT_TIMEOUT=60000
        ports:
          - 4444
        networks:
         - docnet
 chrome:
        image: capitalt/selenium-node-chrome-debug:3.6.0
#        volumes:
#        - /dev/shm:/dev/shm #mitigates the chromium issue described at https://code.google.com/p/chromium/issues/detail?id=519952
        depends_on:
         - selenium-hub-$network_prefix
        environment:
         - HUB_PORT_4444_TCP_ADDR=selenium-hub-$network_prefix
         - HUB_PORT_4444_TCP_PORT=4444
         - NODE_MAX_SESSION=1
        ports:
         - 5900
        networks:
         - docnet

 firefox:
        image: capitalt/selenium-node-firefox-debug:3.6.0
        depends_on:
         - selenium-hub-$network_prefix
        environment:
         - HUB_PORT_4444_TCP_ADDR=selenium-hub-$network_prefix
         - HUB_PORT_4444_TCP_PORT=4444
         - NODE_MAX_SESSION=1
        ports:
         - 5900
        networks:
         - docnet
" > docker-compose.yml

#cat docker-compose.yml

# Fire the grid
docker-compose up -d
docker-compose scale chrome=$number_of_runners
#docker-compose ps

# Wait some seconds to have everything up
echo "Waiting 10 sec to setup the grid"
sleep 10

# Get the IP of the container
#ip_address=$(docker inspect $container | grep "IPAddress")
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${network_name,,}_selenium-hub-${network_prefix}_1
echo $network_name
