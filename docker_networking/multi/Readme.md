# Starting

## Run the example local

```bash
./start-vms.sh
eval $(docker-machine env --swarm swarm-master)
# Validate
docker info
# Run docker compose
docker-compose up -d
```

## Run the example on digital ocean

```bash
export DIGITALOCEAN_ACCESS_TOKEN=<TOKEN>
export DIGITALOCEAN_PRIVATE_NETWORKING=true
export DIGITALOCEAN_SSH_USER=core
export DIGITALOCEAN_IMAGE=coreos-alpha
# Start all VM's
./start-digital-ocean-vms.sh
eval $(docker-machine env --swarm swarm-master)
# Validate
docker info
# Get the IP of the cluster store
export CLUSTER_STORE_IP=$(docker-machine ssh cluster-store 'ifconfig eth1 | grep "inet " | cut -d " " -f 10')
# Run docker compose
docker-compose up -d
```

## Network

```bash
docker network inspect multi_redis
...
# Return 3 Container
docker network inspect multi_front
...
# Returns 1 Container
docker exeec <hash-todo-app> exec ifconfig
```

Fetch the hash of the todo-app and ping the other containers.

```bash
docker exec <hash> ping -c 5 redis-slave # works
docker exec <hash> ping -c 5 redis-master # works
```

Fetch the hash of the redis-master and ping the other containers.

```bash
docker exec <hash> ping -c 5 redis-slave # works
docker exec <hash> ping -c 5 todo-app # fails
```

Fetch the hash of the redis-slave and connect it to the front network.

```bash
docker exec <hash> ping -c 5 todo-app # fails
docker network connect single_front <hash>
docker exec <hash> ping -c 5 todo-app # works
```

## Failover

```bash
watch -n 0.5 docker exec <hash-todo-app> nslookup redis-slave
# Scale redis slaves
docker-compose scale redis-slave=10
# kill container 1
docker kill <hash-redis-slave-1>
# Restart complete Node
docker-machine restart swarm-node-0X
```
