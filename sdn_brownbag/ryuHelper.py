"""
        ryu helper classes
        @author: Johannes Maximilian Scheuermann
"""

from ryu.lib.packet import packet, ethernet, arp, ipv4, ether_types
from ryu.ofproto import ofproto_v1_3


class RyuPacket():
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, ev, logger):
        self.pkt = packet.Packet(ev.msg.data)
        self.ev = ev
        self.pkt_eth = self.pkt.get_protocol(ethernet.ethernet)
        self.pkt_arp = self.pkt.get_protocol(arp.arp)
        self.pkt_ipv4 = self.pkt.get_protocol(ipv4.ipv4)
        self.logger = logger
        self.datapath = self.ev.msg.datapath

    def get_datapath(self):
        return self.datapath

    def get_dpid(self):
        return self.datapath.id

    def get_in_port(self):
        # return self.ev.msg.in_port
        return self.ev.msg.match['in_port']

    def is_arp_request(self):
        if self.pkt_arp is None:
            return False
        return self.pkt_arp.opcode == arp.ARP_REQUEST

    def get_mac_src(self):
        if not self.pkt_eth:
            return None
        return self.pkt_eth.src

    def get_mac_dst(self):
        if not self.pkt_eth:
            return None
        return self.pkt_eth.dst

    def get_ip_src(self):
        if not self.pkt_ipv4:
            return None
        return self.pkt_ipv4.src

    def get_ip_dst(self):
        if not self.pkt_ipv4:
            return None
        return self.pkt_ipv4.dst

    def get_arp_ip_src(self):
        if not self.pkt_arp:
            return None
        return self.pkt_arp.src_ip

    def get_arp_ip_dst(self):
        if not self.pkt_arp:
            return None
        return self.pkt_arp.dst_ip

    def flood(self):
        self.send_packet(self.datapath.ofproto.OFPP_FLOOD)

    def send_packet(self, port):
        ofproto = self.datapath.ofproto
        parser = self.datapath.ofproto_parser

        self.pkt.serialize()
        actions = [parser.OFPActionOutput(port=port)]
        out = parser.OFPPacketOut(datapath=self.datapath,
                                  buffer_id=ofproto.OFP_NO_BUFFER,
                                  in_port=ofproto.OFPP_CONTROLLER,
                                  actions=actions,
                                  data=self.pkt.data)
        self.datapath.send_msg(out)

    def answer_arp(self, mac, port):
        pkt = packet.Packet()
        pkt.add_protocol(ethernet.ethernet(ethertype=self.pkt_eth.ethertype,
                                           dst=self.get_mac_src(),
                                           src=mac))

        pkt.add_protocol(arp.arp(opcode=arp.ARP_REPLY,
                                 src_mac=mac,
                                 src_ip=self.get_arp_ip_dst(),
                                 dst_mac=self.pkt_arp.src_mac,
                                 dst_ip=self.get_arp_ip_src()))

        ofproto = self.datapath.ofproto
        parser = self.datapath.ofproto_parser

        pkt.serialize()
        actions = [parser.OFPActionOutput(port=port)]
        out = parser.OFPPacketOut(datapath=self.ev.msg.datapath,
                                  buffer_id=ofproto.OFP_NO_BUFFER,
                                  in_port=ofproto.OFPP_CONTROLLER,
                                  actions=actions,
                                  data=pkt.data)
        self.datapath.send_msg(out)


class RyuFlow():
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, ev, logger):
        self.ev = ev
        self.logger = logger

    def add_flow(self, datapath, match, actions, idle_timeout, hard_timeout):
        ofproto = datapath.ofproto
        inst = [datapath.ofproto_parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions)]

        mod = datapath.ofproto_parser.OFPFlowMod(
            datapath=datapath,
            priority=ofproto.OFP_DEFAULT_PRIORITY,
            match=match,
            idle_timeout=idle_timeout,
            hard_timeout=hard_timeout,
            instructions=inst)

        self.logger.info("Set Flow: %s", mod)
        self.ev.msg.datapath.send_msg(mod)

    def add_buffer_flow(self, datapath, priority, match, actions, buffer_id=None):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,
                                             actions)]
        if buffer_id:
            mod = parser.OFPFlowMod(datapath=datapath, buffer_id=buffer_id,
                                    priority=priority, match=match,
                                    instructions=inst)
        else:
            mod = parser.OFPFlowMod(datapath=datapath, priority=priority,
                                    match=match, instructions=inst)
        datapath.send_msg(mod)
