"""
        SDN Learning Switch
        @author: Johannes Maximilian Scheuermann
"""

from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, set_ev_cls, CONFIG_DISPATCHER
from ryu.ofproto import ofproto_v1_3

from ryuHelper import RyuPacket, RyuFlow


class LearningSwitch(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(LearningSwitch, self).__init__(*args, **kwargs)
        self.mac_to_port = {}

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # install table-miss flow entry
        #
        # We specify NO BUFFER to max_len of the output action due to
        # OVS bug. At this moment, if we specify a lesser number, e.g.,
        # 128, OVS will send Packet-In with invalid buffer_id and
        # truncated packet data. In that case, we cannot output packets
        # correctly.  The bug has been fixed in OVS v2.1.0.
        RyuFlow(ev, self.logger).add_buffer_flow(datapath, 0, parser.OFPMatch(),
                                          [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER, ofproto.OFPCML_NO_BUFFER)])

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def packet_in_handler(self, ev):
        ryu_packet = RyuPacket(ev, self.logger)

        self.mac_to_port.setdefault(ryu_packet.get_dpid(), {})
        self.logger.info("packet in %s %s %s %s", ryu_packet.get_dpid(), ryu_packet.get_mac_src(),
                         ryu_packet.get_mac_dst(),
                         ryu_packet.get_in_port())

        # Learn a path by incoming packet
        self.mac_to_port[ryu_packet.get_dpid()][ryu_packet.get_mac_src()] = ryu_packet.get_in_port()

        if ryu_packet.get_mac_dst() in self.mac_to_port[ryu_packet.get_dpid()]:
            out_port = self.mac_to_port[ryu_packet.get_dpid()][ryu_packet.get_mac_dst()]
            ryu_packet.send_packet(out_port)
        else:
            ryu_packet.flood()
            return

        RyuFlow(ev, self.logger).add_flow(
            ryu_packet.get_datapath(),
            ryu_packet.get_datapath().ofproto_parser.OFPMatch(in_port=ryu_packet.get_in_port(),
                                                              eth_dst=ryu_packet.get_mac_dst()),
            [ryu_packet.get_datapath().ofproto_parser.OFPActionOutput(out_port)],
            0,
            0)