#!/bin/bash
echo "Start consul as K/V store"

docker-machine create \
    -d virtualbox \
    cluster-store

docker $(docker-machine config cluster-store) run -d \
    -p "8500:8500" \
    -h "consul" \
    --restart always \
    progrium/consul -server -bootstrap -ui-dir /ui

echo "Start Swarm Master"

docker-machine create \
    --driver virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip cluster-store):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cluster-store):8500" \
    --engine-opt="cluster-advertise=eth1:0" \
    swarm-master

echo "Start Docker Registrator on Swarm Master"
docker $(docker-machine config swarm-master) run -d \
    --name=registrator \
    --hostname=$(docker-machine ip swarm-master) \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:latest \
    consul://$(docker-machine ip cluster-store):8500

for i in {0..2}
do
echo "Start Swarm Node 0$i"
docker-machine create \
    --driver virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip cluster-store):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip cluster-store):8500" \
    --engine-opt="cluster-advertise=eth1:0" \
    swarm-node-0$i

echo "Start Docker Registrator on Swarm Node 0$i"
docker $(docker-machine config swarm-node-0$i) run -d \
    --name=registrator \
    --hostname=$(docker-machine ip swarm-node-0$i) \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:latest \
    consul://$(docker-machine ip cluster-store):8500
done

echo "Execute eval $(docker-machine env --swarm swarm-master)"
