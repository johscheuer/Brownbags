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
