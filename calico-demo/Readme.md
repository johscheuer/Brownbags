# Demo for Calico 2.6

## Setup the demo environment

First fetch the needed files for the vagrant setup.

```bash
$ curl -sLO https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/vagrant/Vagrantfile
$ curl -sLO https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/vagrant/master-config.yaml
$ curl -sLO https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/vagrant/node-config.yaml
```

Start the demo setup

```bash
$ vagrant up
```

### Network Setup

|  Hostname | IP  |
|---|---|
| k8s-master   |  172.18.18.101 |
| k8s-node-01  |  172.18.18.102 |
| k8s-node-02  |  172.18.18.103 |

Validate that every node can be pinged from each host:

```bash
$ ping -c 4 172.18.18.101
$ ping -c 4 172.18.18.102
$ ping -c 4 172.18.18.103
```

Validate that etcd is accessible:

```bash
$ curl -sL http://172.18.18.101:2379/version | jq '.'
```

Now you can configure your kubectl (if not installed [install](https://kubernetes.io/docs/tasks/tools/install-kubectl) it first):

```bash
$ kubectl config set-cluster calico-demo --server=http://172.18.18.101:8080
$ kubectl config set-context calico-demo --cluster=calico-demo
$ kubectl config use-context calico-demo
# Validate
$ kubectl config current-context
```

## Install calico

Calico can be installed as an CNI Plugin. In the hosted mode (used in this demo) all compents are deployed as containers and with a Kubernetes Daemonset (exceot for the Policy Controller).

```bash
$ kubectl apply -f calico.yaml
```

Verify that the nodes are noe `Ready`:

```bash
$ kubectl get nodes
NAME            STATUS                     ROLES     AGE       VERSION
172.18.18.101   Ready,SchedulingDisabled   <none>    11m       v1.7.5
172.18.18.102   Ready                      <none>    11m       v1.7.5
172.18.18.103   Ready                      <none>    11m       v1.7.5
```

Now install the Kubernetes DNS addon:

```bash
$ kubectl apply -f kubedns.yaml
```

And verify that all pods are up and running:

```bash
$ kubectl -n kube-system get po
NAME                                       READY     STATUS    RESTARTS   AGE
calico-kube-controllers-3994748863-wjm4w   1/1       Running   0          4m
calico-node-7tp05                          2/2       Running   0          4m
calico-node-ctzsc                          2/2       Running   0          4m
calico-node-jl2bc                          2/2       Running   0          4m
kube-dns-651797986-bzmcq                   3/3       Running   0          1m
```

On the nodes:

```bash
$ ifconfig tunl0
```

## Demo

At first create a namespace for the demo:

```bash
$ kubectl create ns calico-demo
```

Run two nginx web server:

```bash
$ kubectl run --namespace=calico-demo nginx --replicas=2 --image=nginx:stable-alpine
```

And now expose the service:

```bash
$ kubectl expose --namespace=calico-demo --port=80 --type=NodePort deployment nginx
# Fetch the nodePort
$ PORT=$(kubectl -n calico-demo get svc nginx -o json | jq '.spec.ports[].nodePort')
$ curl 172.18.18.101:$PORT
```

Create a pod to access the nginx from inside the cluster

```bash
$ kubectl run --namespace=calico-demo access --rm -ti --image busybox:1.27.2 /bin/sh
```

Create a Network Policy:

```bash
kubectl apply -f np-deny.yml
```

Test all connections. After this allow the access pod to access the nginx.

```bash
kubectl apply -f np-allow.yml
```

Delete the demo namespace:

```bash
kubectl delete ns calico-demo
```
