# Introduction to Marathon
## Slides
[Slides](slides/index.html)

## Hands-on
### Docker setup
#### Requierments
- [Docker 1.6+](https://docs.docker.com/installation)
- [Docker-machine 0.4+](https://docs.docker.com/machine/install-machine)
- [Virtualbox 4+](https://www.virtualbox.org/)

#### Create the cluster

```Bash
# Only on OSX if you all ready crated the default VM and it's stopped
docker-machine start default
eval $(docker-machine env default)
export SWARM_TOKEN=$(docker run swarm create)
docker-machine stop default
# Create the cluster
docker-machine create \
        -d virtualbox \
        --swarm \
        --swarm-master \
        --swarm-discovery token://$SWARM_TOKEN \
        --virtualbox-memory 3072 \
        --virtualbox-cpu-count 1 \
        mesos-master

docker-machine create \
        -d virtualbox \
        --swarm \
        --swarm-discovery token://$SWARM_TOKEN \
        --virtualbox-memory 3072 \
        --virtualbox-cpu-count 1 \
        mesos-agent-00

docker-machine create \
        -d virtualbox \
        --swarm \
        --swarm-discovery token://$SWARM_TOKEN \
        --virtualbox-memory 3072 \
        --virtualbox-cpu-count 1 \
        mesos-agent-01

# Connect to the cluster
eval $(docker-machine env --swarm mesos-master)
docker info
```

#### Install Mesos on the cluster
- Todo add local registry (mirror)
- Add picture

```Bash
# Zookeeper
docker run -d \
-e constraint:node==mesos-master \
--net=host \
--restart=always \
jplock/zookeeper:3.4.6

# Mesos master
docker run -d \
-e constraint:node==mesos-master \
-e MESOS_HOSTNAME=$(Docker-machine ip mesos-master) \
-e MESOS_IP=$(Docker-machine ip mesos-master) \
-e MESOS_ZK=zk://$(Docker-machine ip mesos-master):2181/mesos \
-e MESOS_PORT=5050 \
-e MESOS_LOG_DIR=/var/log/mesos \
-e MESOS_QUORUM=1 \
-e MESOS_WORK_DIR=/var/lib/mesos \
--net=host \
--restart=always \
mesoscloud/mesos-master:0.24.1-centos-7

# Mesos Agent on mesos master
docker run -d \
-e constraint:node==mesos-master \
-e MESOS_HOSTNAME=$(Docker-machine ip mesos-master) \
-e MESOS_IP=$(Docker-machine ip mesos-master) \
-e MESOS_MASTER=zk://$(Docker-machine ip mesos-master):2181/mesos \
-e MESOS_LOG_DIR=/var/log/mesos \
-e MESOS_LOGGING_LEVEL=INFO \
-e MESOS_ATTRIBUTES='rack:1;disk:ssd' \
--net=host \
--restart=always \
-v /sys/fs/cgroup:/sys/fs/cgroup \
-v /var/run/docker.sock:/var/run/docker.sock \
--pid=host \
--restart=always \
mesoscloud/mesos-slave:0.24.1-centos-7 \
mesos-slave

# Mesos Agent 1
docker run -d \
-e constraint:node==mesos-agent-00 \
-e MESOS_HOSTNAME=$(Docker-machine ip mesos-agent-00) \
-e MESOS_IP=$(Docker-machine ip mesos-agent-00) \
-e MESOS_MASTER=zk://$(Docker-machine ip mesos-master):2181/mesos \
-e MESOS_LOG_DIR=/var/log/mesos \
-e MESOS_LOGGING_LEVEL=INFO \
-e MESOS_ATTRIBUTES='rack:2;disk:ssd' \
--net=host \
-v /sys/fs/cgroup:/sys/fs/cgroup \
-v /var/run/docker.sock:/var/run/docker.sock \
--pid=host \
--restart=always \
mesoscloud/mesos-slave:0.24.1-centos-7 \
mesos-slave

# Mesos Agent 2
docker run -d \
-e constraint:node==mesos-agent-01 \
-e MESOS_HOSTNAME=$(Docker-machine ip mesos-agent-01) \
-e MESOS_IP=$(Docker-machine ip mesos-agent-01) \
-e MESOS_MASTER=zk://$(Docker-machine ip mesos-master):2181/mesos \
-e MESOS_LOG_DIR=/var/log/mesos \
-e MESOS_LOGGING_LEVEL=INFO \
-e MESOS_ATTRIBUTES='rack:3;disk:hdd' \
--net=host \
-v /sys/fs/cgroup:/sys/fs/cgroup \
-v /var/run/docker.sock:/var/run/docker.sock \
--pid=host \
--restart=always \
mesoscloud/mesos-slave:0.24.1-centos-7 \
mesos-slave

# Marathon
docker run -d \
-e constraint:node==mesos-master \
-e MARATHON_ZK=zk://$(Docker-machine ip mesos-master):2181/marathon \
-e MARATHON_MASTER=zk://$(Docker-machine ip mesos-master):2181/mesos \
-e MARATHON_HOSTNAME=$(Docker-machine ip mesos-master) \
-e MARATHON_HTTPS_ADDRESS=$(Docker-machine ip mesos-master) \
-e MARATHON_HTTP_ADDRESS=$(Docker-machine ip mesos-master) \
--net=host \
--restart=always \
mesoscloud/marathon:0.11.0-centos-7
```

The Web UI is available at [http://$(Docker-machine ip mesos-master):5050/#/](http://$(Docker-machine ip mesos-master):5050/#/) and marathon at [http://$(Docker-machine ip mesos-master):8080](http://$(Docker-machine ip mesos-master):8080)

### Running the examples
#### Constraints

```Bash
# Cluster example
http $(docker-machine ip mesos-master):8080/v2/apps < examples/constraints/constraint-cluster.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/constraint-cluster
# Groupby example
http $(docker-machine ip mesos-master):8080/v2/apps < examples/constraints/constraint-groupby.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/constraint-groupby

# Like example
http $(docker-machine ip mesos-master):8080/v2/apps < examples/constraints/constraint-like.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/constraint-like

# Unique example
 http $(docker-machine ip mesos-master):8080/v2/apps < examples/constraints/constraint-unique.json

 http DELETE $(docker-machine ip mesos-master):8080/v2/apps/constraint-unique

 # Unlike example
 http $(docker-machine ip mesos-master):8080/v2/apps < examples/constraints/constraint-unlike.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/constraint-unlike
```

#### Docker

```Bash
# Arguments example
http $(docker-machine ip mesos-master):8080/v2/apps < examples/docker/docker-args.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/arg-example

# Bridge
http $(docker-machine ip mesos-master):8080/v2/apps < examples/docker/docker-bridge.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/hello-server

# Volumes
http $(docker-machine ip mesos-master):8080/v2/apps < examples/docker/write-to-disk.json

http $(docker-machine ip mesos-master):8080/v2/apps < examples/docker/read-from-disk.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/write-to-disk

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/read-from-disk
```

#### Health Checks

```Bash
http $(docker-machine ip mesos-master):8080/v2/apps < examples/health-checks/health-check.json

http DELETE $(docker-machine ip mesos-master):8080/v2/apps/health-check
```
