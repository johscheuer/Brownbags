#!/bin/sh

confd -watch -backend etcd -node http://etcd:2379 -log-level="error" &

while true; do
  cat /tmp/myconf.conf
  sleep 2
done
