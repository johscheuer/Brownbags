# Application configuration in containers

Slides: missing

## Confd Demo

### etcd

I use the officially etcd image from [Quay](https://quay.io).

### Client

Inside the `client_image` directory you can find the `Dockerfile` and the `start_up.sh`. The start-up script starts confd in daemon mode and prints every 2 seconds the input of the generated file.

### etcd init

This is a simple container that generates the initial state of the etcd container. The provision script uses `curl` to initialize the etcd:

```
$ cat etcd_init/provision_etcd.sh
#!/bin/sh

echo "Creating prod keys"
curl -s -L -X PUT -d value="Live" http://etcd:2379/v2/keys/prod_demo/name
curl -s -L -X PUT -d value="Prod val1" http://etcd:2379/v2/keys/prod_demo/range_val/val1
curl -s -L -X PUT -d value="Prod val2" http://etcd:2379/v2/keys/prod_demo/range_val/val2

echo "Creating demo keys"
curl -s -L -X PUT -d value="Testing" http://etcd:2379/v2/keys/test_demo/name
curl -s -L -X PUT -d value="Test val1" http://etcd:2379/v2/keys/test_demo/range_val/val1
curl -s -L -X PUT -d value="Test val2" http://etcd:2379/v2/keys/test_demo/range_val/val2

echo "Goodbye"
```

## Start the Example

```
$ docker-compose build
$ docker-compose up -d
Creating dockerappconfig_etcd_1
Creating dockerappconfig_etcd_init_1
Creating dockerappconfig_test_client_1
Creating dockerappconfig_prod_client_1

$ docker-compose ps
            Name                           Command               State                    Ports
----------------------------------------------------------------------------------------------------------------
dockerappconfig_etcd_1          /etcd -name etcd -advertis ...   Up       2379/tcp, 2380/tcp, 4001/tcp, 7001/tcp
dockerappconfig_etcd_init_1     /bin/sh -c /usr/bin/provis ...   Exit 0
dockerappconfig_prod_client_1   /bin/sh -c /usr/bin/start_ ...   Up
dockerappconfig_test_client_1   /bin/sh -c /usr/bin/start_ ...   Up
```

### Change the configuration

Open two terminals or use [tmux](https://tmux.github.io).

#### First terminal

Show the logs of the "production" container:

```
$ docker logs -f dockerappconfig_prod_client_1
....
```

#### Second terminal

Use the Shell from the test container (you can also use the production container):

```
$ docker exec -ti dockerappconfig_test_client_1 sh
```

Update the name in the production space:

```
$ curl -L -X PUT -d value="Hans" http://etcd:2379/v2/keys/prod_demo/name
```

Add some range values in the production space:

```
$ for i in `seq 3 9`; do curl -L -X PUT -d value="Prod val$i" http://etcd:2379/v2/keys/prod_demo/range_val/val$i; done
```

# References

- [Confd](https://github.com/kelseyhightower/confd)
