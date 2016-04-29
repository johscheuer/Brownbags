#!/bin/bash
sudo ovs-vsctl set bridge s1 protocols=OpenFlow13
echo "Validate OpenFlow Version"
sudo ovs-ofctl -O OpenFlow13 dump-flows s1

ryu-manager --verbose  learning_switch.py
