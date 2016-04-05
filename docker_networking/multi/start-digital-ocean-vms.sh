#!/bin/bash
echo "Start consul as K/V store"

docker-machine create \
    -d digitalocean \
    cluster-store

CLUSTER_STORE_IP=$(docker-machine ssh cluster-store 'ifconfig eth1 | grep "inet " | cut -d " " -f 10')

echo "Cluster store private IP ${CLUSTER_STORE_IP}"

docker $(docker-machine config cluster-store) run -d \
    -p "${CLUSTER_STORE_IP}:8500:8500" \
    -h "consul" \
    --restart always \
    progrium/consul -server -bootstrap -ui-dir /ui

echo "Start Swarm Master"

docker-machine create \
    --driver digitalocean \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://${CLUSTER_STORE_IP}:8500" \
    --engine-opt="cluster-store=consul://${CLUSTER_STORE_IP}:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    swarm-master

echo "Start Docker Registrator"
docker $(docker-machine config swarm-master) run -d \
    --name=registrator \
    --hostname=$(docker-machine ssh swarm-master 'ifconfig eth1 | grep "inet " | cut -d " " -f 10') \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:latest \
    consul://${CLUSTER_STORE_IP}:8500

for i in {0..2}
do
echo "Start Swarm Node 0$i"
docker-machine create \
    --driver digitalocean \
    --swarm \
    --swarm-discovery="consul://${CLUSTER_STORE_IP}:8500" \
    --engine-opt="cluster-store=consul://${CLUSTER_STORE_IP}:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    swarm-node-0$i

echo "Start Docker Registrator on Swarm Node 0$i"
docker $(docker-machine config swarm-node-0$i) run -d \
    --name=registrator \
    --hostname=$(docker-machine ssh swarm-node-0$i 'ifconfig eth1 | grep "inet " | cut -d " " -f 10') \
    --volume=/var/run/docker.sock:/tmp/docker.sock \
    gliderlabs/registrator:latest \
    consul://${CLUSTER_STORE_IP}:8500
done

echo "Execute eval $(docker-machine env --swarm swarm-master)"
