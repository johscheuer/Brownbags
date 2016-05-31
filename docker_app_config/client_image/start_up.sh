#!/bin/sh

confd -watch -backend etcd -node http://etcd:2379 -log-level="error" &

while true; do
  $date
  cat /tmp/myconf.conf
  sleep 5
done
