# Autoscaling brownbag

## Pre

Spin up a Kubernetes Cluster for e.q. with [Vagrant](https://github.com/kubernetes/kubernetes/blob/v1.2.4/docs/devel/developer-guides/vagrant.md)

```bash
export KUBERNETES_NODE_MEMORY=2048
export NUM_NODES=2
./cluster/kube-up.sh
alias kubectl="./cluster/kubectl"
kubectl get nodes
kubectl get pods
```

## Starting the demo

### Deploy the app

```bash
# Start all components
kubectl create -f todo-app
kubectl get pods
```

### Autoscaling

```bash
kubectl autoscale rc todo-app --min=1 --max=10 --cpu-percent=50
kubectl get hpa
```

### Loadtest

Watch the current pods

```bash
watch kubectl get pods
```

Set some load:

```bash
boom -c 250 -n 40000 http://10.245.1.3:<Port>
```

Watch it scale up and down. :)
