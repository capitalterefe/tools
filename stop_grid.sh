#!/bin/bash

network_name=$1
path=/tmp

echo "Stopping and removing grid: $network_name in $path"

pushd $path/$network_name

# Dispose the grid
docker-compose ps
docker-compose down
docker-compose ps

# Remove the directory
cd ..
rm -rf $network_name

popd
