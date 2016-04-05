#!/usr/bin/python

from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.cli import CLI
from mininet.log import setLogLevel
from mininet.link import TCLink
"""
	SDN Mininet
	@author: Johannes Maximilian Scheuermann
"""


def SDNNet():
    print "Start mininet for task 1/2"

    net = Mininet(topo=None, build=False, link=TCLink)

    print("Create the hosts")
    h1 = net.addHost("h1", ip="192.168.0.1/24", mac="aa:aa:aa:aa:aa:01")
    h2 = net.addHost("h2", ip="192.168.0.2/24", mac="aa:aa:aa:aa:aa:02")
    h3 = net.addHost("h3", ip="192.168.0.3/24", mac="aa:aa:aa:aa:aa:03")
    h4 = net.addHost("h4", ip="192.168.0.4/24", mac="aa:aa:aa:aa:aa:04")

    print("Create the switch")
    s1 = net.addSwitch("s1", mac="cc:cc:cc:cc:cc:cc", dpid="0000000000000001")

    print("Create the links")
    net.addLink(h1, s1, bw=200)
    net.addLink(h2, s1)
    net.addLink(h3, s1)
    net.addLink(h4, s1)

    print("Add controller")
    controller = net.addController("controller", controller=RemoteController, ip="127.0.0.1")
    net.build()

    print("Connect controller")
    s1.start([controller])

    print("Start mininet CLI")
    CLI(net)
    net.stop()


if __name__ == "__main__":
    setLogLevel("info")
    SDNNet()
