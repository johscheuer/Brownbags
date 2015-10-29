#!/bin/bash
echo "Fetching Swarm token"
docker-machine start default
eval $(docker-machine env default)
export SWARM_TOKEN=$(docker run swarm create)
docker-machine stop default

echo "Starting up the VM's"
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

echo "Check cluster"
eval $(docker-machine env --swarm mesos-master)
docker info

echo "Install mesos"
docker run -d \
-e constraint:node==mesos-master \
--net=host \
--restart=always \
jplock/zookeeper:3.4.6

echo "Mesos master"
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

echo "Mesos Agent on mesos master"
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

echo "Mesos Agent 1"
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

echo "Mesos Agent 2"
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

echo "Marathon"
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
