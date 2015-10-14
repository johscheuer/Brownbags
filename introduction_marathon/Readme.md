# Introduction to Marathon
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
### Running the examples
```Bash
cat hello-inovex.json cd v
{
  "id": "hello-inovex", 
  "cmd": "while [ true ] ; do echo 'Hello inovex' ; sleep 5 ; done",
  "cpus": 0.1,
  "mem": 10.0,
  "instances": 1
}
# Submit the app
http http://10.141.141.10:8080/v2/apps < hello-inovex.json 
# Or with curl
curl -X POST http://10.141.141.10:8080/v2/apps -d @hello-inovex.json -H "Content-type: application/json"
# better output
curl -sX PUT http://10.141.141.10:8080/v2/apps/hello-inovex -d @hello-inovex-2.json -H "Content-type: application/json" | python -mjson.tool
```
#### Submit a change 
```Bash
cat hello-inovex-change.json 
{
  "id": "hello-inovex", 
  "cmd": "while [ true ] ; do echo 'I am awesome!' ; sleep 5 ; done",
  "cpus": 0.1,
  "mem": 10.0,
  "instances": 1
}
# Submit the change 
http PUT http://10.141.141.10:8080/v2/apps/hello-inovex < hello-inovex-change.json
```
#### Scale an application
```Bash
#Web UI click scale ...
cat hello-inovex-scale.json 
{
  "id": "hello-inovex", 
  "cmd": "while [ true ] ; do echo 'I am awesome!' ; sleep 5 ; done",
  "cpus": 0.1,
  "mem": 10.0,
  "instances": 1
}
# Submit the change 
http PUT http://10.141.141.10:8080/v2/apps/hello-inovex < hello-inovex-scale.json
```
#### What happens when  a task finish:
```Bash
cat task-finish.json 
{
    "id": "task-finish", 
    "cmd": "echo start; sleep 5; echo finish",
    "cpus": 0.1,
    "mem": 10.0,
    "instances": 1
}
# Submit the change 
http POST http://10.141.141.10:8080/v2/apps < task-finish.json 
```
#### Delete an application
```Bash
http DELETE http://10.141.141.10:8080/v2/apps/hello-inovex
```
#### Docker
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
# Submit
http POST http://10.141.141.10:8080/v2/apps < docker-webserver.json
# After the Container has started go to
http http://10.141.141.10:31000
```

#### Remote resources
Inside the vagrant vm
```Bash
mkdir remote && cd remote
cat hello-inovex.sh 
#!/bin/bash
while [ true ] ; do echo 'Hello inovex' ; sleep 5 ; done
```
Start a webserver on the vagrant machine
```Bash
python -m SimpleHTTPServer 8000
```
Run the Task
```Bash
cat hello-inovex-remote.json
{
  "id": "hello-inovex-remote", 
  "cmd": "chmod u+x ./hello-inovex.sh && ./hello-inovex.sh",
  "cpus": 0.1,
  "mem": 10.0,
  "instances": 1,
  "uris": [
        "http://10.141.141.10:8000/hello-inovex.sh"
  ]
}
# Submit
http POST http://10.141.141.10:8080/v2/apps < hello-inovex-remote.json
```
#### Packed remote resources
Inside the vagrant vm
```Bash
pwd
/home/vagrant/remote
tar cfz hello-inovex.tar.gz hello-inovex.sh
```
Start a webserver on the vagrant machine
```Bash
python -m SimpleHTTPServer 8000
```
On your host
```Bash
cat hello-inovex-packed.json 
{
    "id": "hello-inovex-packed", 
    "cmd": "chmod u+x ./hello-inovex.sh && ./hello-inovex.sh",
    "cpus": 0.1,
    "mem": 10.0,
    "instances": 1,
    "uris": [
        "http://10.141.141.10:8000/hello-inovex.tar.gz"
    ]
}
# Submit
http POST http://10.141.141.10:8080/v2/apps < hello-inovex-packed.json
```
#### Grouping
```Bash
cat demo-group.json
{
  "id": "/demo-group",
  "groups": [
    {
      "id": "./forward",
      "apps": [
         {  
            "id": "./fc", 
            "cmd": "for i in $(seq 1 100); do echo $i; sleep 1; done",
            "cpus": 0.1,
            "mem": 10.0,
            "instances": 1
          },
          {  
            "id": "./hellofc", 
            "cmd": "for i in $(seq 1 100); do echo 'Hello GrikdKA'; sleep 1; done",
            "cpus": 0.1,
            "mem": 10.0,
            "instances": 1
          }
       ]
    },{
      "id": "./backward",
      "dependencies": ["../forward"],
      "apps": [
         {
            "id": "./bc", 
            "cmd": "for i in $(seq 1 100); do echo $i; sleep 1; done",
            "cpus": 0.1,
            "mem": 10.0,
            "instances": 1
         },
         {  
            "id": "./hellobc", 
            "cmd": "for i in $(seq 1 100); do echo 'Hello GrikdKA' | rev; sleep 1; done",
            "cpus": 0.1,
            "mem": 10.0,
            "instances": 1
         }
      ]
    }
  ]
}
# Submit
http http://10.141.141.10:8080/v2/groups < demo-group.json
```
Scale a complete group
```Bash
cat scale.json
{ 
  "scaleBy": 2 
}
# Submit
http PUT http://10.141.141.10:8080/v2/groups/demo-group < scale.json
```
#### Downtimelose deployments
The option minimumHealthCapacity (percantage) can be used for deployments.