# Networking Brownbag

## CLI

### Create networks

```bash
docker network create -d=bridge front
docker network create -d=bridge redis
```

### Start container

```bash
docker run -d --net=redis --net-alias=redis-master redis
docker run -d --net=redis --net-alias=redis-slave johscheuer/redis-slave:v1
docker run -d --net=front --net-alias=todo-app -p 80:3000 --name=todo-app johscheuer/todo-app-web:v2

docker network inspect redis
# Add Container to redis network
# Watch the the health state
watch http 192.168.99.100/health
docker network connect redis $(docker ps -q -f="name=todo-app")
docker network inspect redis
```

### Inspect networks

```bash
docker network inspect redis
docker network inspect front
```

## Compose examples

Inside the directory `single` and `multi` are Docker Compose (and Machine) examples.

- [Local](single/Readme.md)
- [Multi-Host](multi/Readme.md)
