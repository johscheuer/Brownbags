# Mesos-DNS - Service discovery in Mesos
## Slides
[Slides](slides/index.html)
## Hands-on
### Vagrant setup
```Bash
git clone https://github.com/mesosphere/playa-mesos.git
cd playa-mesos
bin/test
# Adjust the Memory of the VM in config.json
vagrant up
```

The Web UI is available at http://10.141.141.10:5050/#/ and marathon at http://10.141.141.10:8080
### Setting up mesos-dns
```Bash
curl -L https://github.com/mesosphere/mesos-dns/releases/download/v0.4.0/mesos-dns-v0.4.0-linux-amd64.gz -O
gunzip mesos-dns-v0.4.0-linux-amd64.gz
sudo mkdir /usr/local/mesos-dns
sudo mv ./mesos-dns-v0.4.0-linux-amd64 /usr/local/mesos-dns/mesos-dns
chmod +x /usr/local/mesos-dns/mesos-dns
# set up the config file
cat /usr/local/mesos-dns/mesos-dns-config.json
{
        "masters": ["10.141.141.10:5050"],
        "refreshSeconds": 60,
        "ttl": 60,
        "domain": "mesos",
        "port": 53,
        "resolvers": ["8.8.8.8"],
        "timeout": 5,
        "dsnon": true,
        "externalon": true,
        "listener": "10.141.141.10"
}
# Start mesos dns
sudo /usr/local/mesos-dns/mesos-dns -config /usr/local/mesos-dns/mesos-dns-config.json -v 10
# Validate it from the host
dig master.mesos @10.141.141.10 +short
10.141.141.10
127.0.1.1
```
### Change nameserver on slave(s)
```Bash
sudo sed -i '1s/^/nameserver 10.141.141.10\n /' /etc/resolv.conf
dig master.mesos +short
10.141.141.10
127.0.1.1
```
### Running mesos DNS HA
```Bash
cat mesos-dns.json
{
    "cmd": "/usr/local/mesos-dns/mesos-dns -config=/usr/local/mesos-dns/mesos-dns-config.json -v=10",
    "cpus": 0.5,
    "mem": 512,
    "id": "mesos-dns",
    "instances": 1,
    "constraints": [["hostname", "CLUSTER", "10.141.141.10"]]
}
# submit the app
http 10.141.141.10:8080/v2/apps < mesos-dns.json
# Validate again
dig master.mesos @10.141.141.10 +short
10.141.141.10
127.0.1.1
```
### Apps and Mesos DNS
```Bash
cat docker-webserver.json 
{
    "id": "docker-python-server",
    "cmd": "python3 -m http.server 8080",
    "cpus": 0.5,
    "mem": 32.0,
    "container": {
        "type": "DOCKER",
        "docker": {
        "image": "python:3",
        "network": "BRIDGE",
        "portMappings": [
            { "containerPort": 8080, "hostPort": 0 }
        ]
        }
    }
}
# submit 
http 10.141.141.10:8080/v2/apps < docker-webserver.json
# Take a coffee and wait until the container is loaded and the DNS entry is created :)
# Use dns utlis (dig)
dig docker-python-server.marathon.mesos +short
127.0.1.1
# Fetch SRV entry
dig _docker-python-server._tcp.marathon.mesos SRV +short
0 0 31000 docker-python-server-57518-s0.marathon.slave.mesos.
```
# Using the RESTful API
```Bash
http 10.141.141.10:8123/v1/version
http 10.141.141.10:8123/v1/config
http 10.141.141.10:8123/v1/hosts/$host
http 10.141.141.10:8123/v1/services/$service
# Examples
http 10.141.141.10:8123/v1/hosts/docker-python-server.marathon.mesos
http 10.141.141.10:8123/v1/services/_docker-python-server._tcp.marathon.mesos
```
### Mesos DNS + HAProxy
We use the mesosphere script but it would be pretty easy to create your own setup :)
```Bash
# Install HAProxy + chronjob
$ curl -L https://raw.githubusercontent.com/mesosphere/marathon/master/bin/haproxy-marathon-bridge -O
$ chmod +x haproxy-marathon-bridge
$ ./haproxy-marathon-bridge install_haproxy_system 10.141.141.10:8080
# validate 
$ cat /etc/haproxy-marathon-bridge/marathons
10.141.141.10:8080
$ cat /etc/cron.d/haproxy-marathon-bridge
....
$ less /etc/haproxy/haproxy.cfg
...
```
We can now run multiple instances and HAProxy will do loadbalancing
```Bash
# If somebody wants to know what's inside the go-webserver https://github.com/johscheuer/go-hello-webserver
cat hello-server.json
{
  "id": "hello-server",
  "cpus": 0.25,
  "mem": 32.0,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "johscheuer/go-webserver",
      "network": "BRIDGE",
      "portMappings": [
        { "containerPort": 8000, "servicePort": 80 }
      ]
    }
  },
  "instances": 3
}
# Submit
http 10.141.141.10:8080/v2/apps < hello-server.json
# Validate
watch -n 1 http 10.141.141.10
```
### Mesos DNS and intercontainer
```Bash
sudo docker run -ti debian:8
...
apt-get update -y && apt-get install dnsutils -y
dig hello-server.marathon.mesos 
dig SRV _hello-server._tcp.marathon.mesos +short
# Set the DNS search-name
sudo docker run -ti --dns-search=marathon.mesos debian:8
# did not work as expected :(
```
