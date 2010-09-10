/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * RPLForwardingEngineP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include <RPL.h>
#include <ip_malloc.h>
#include <ip.h>

module RPLForwardingEngineP{
  provides interface RPLForwardingEngine as Fwd;
  provides interface IP[uint8_t next];

  uses interface RPLRoutingEngine as Routing;
  uses interface RPLForwardingSend;
  uses interface RPLRank;
  uses interface IPAddress;
  uses interface Leds;
  uses interface RPLDAORoutingEngine as RPLDAORouting;
}

implementation {

  struct in6_addr local_addr;

  error_t initPacket(struct ip6_hdr *hdr, struct in6_addr *nexthop){
    // inser header
    ip_first_hdr_t *flow_hdr;
    flow_hdr = (ip_first_hdr_t*)&hdr->ip6_flow;

    if(call RPLRank.getRank(*nexthop) > call Routing.getRank()){
      // this packet is headed downwards!
      flow_hdr->o_bit = 1;
    }else{
      // this packet is headed upwards!
      flow_hdr->o_bit = 0;
    }

    flow_hdr->r_bit = 0;
    flow_hdr->f_bit = 0;
    flow_hdr->reserved = 0;
    flow_hdr->senderRank = 0;
    flow_hdr->instance_id.id = call Routing.getInstanceID();

    hdr->ip6_hlim = MAX_HOPCOUNT;

    return SUCCESS;
  }

  error_t getNextHop(struct ip6_hdr *hdr, struct rpl_route *routing_hdr, struct in6_addr *next_hop, void* payload, uint8_t o_bit){
    // next hop information goes in to *next_hop
    // check header if it is headed downwards or if there is a source route attched to the packet

    call IPAddress.getLLAddr(&local_addr);

    if(o_bit){
      // This packet is headed downwards (If I am a storing node then getnexthop if not, check payload for source route)
      if(call RPLDAORouting.getStoreState()){
	*next_hop = call RPLDAORouting.getNextHop(hdr->ip6_nxt, hdr->ip6_dst, routing_hdr, payload, &hdr->ip6_plen);
	// for this case, we should add any additional route information to the payload -- done at the routing layer
      }else{
	// get the data from the RR list which is the routing header
	*next_hop = call RPLDAORouting.getNextHop(hdr->ip6_nxt, hdr->ip6_dst, routing_hdr, payload, &hdr->ip6_plen);
      }
    }else{
      // going up the tree just get the next hop with the default prefix
      if(call RPLDAORouting.hasPrefix(&hdr->ip6_dst)){
	// DAO Engine has information on this prefix
	printfUART("DAO Route Request! \n");
	*next_hop = call RPLDAORouting.getNextHop(hdr->ip6_nxt, hdr->ip6_dst, routing_hdr, payload, &hdr->ip6_plen);
	// DAO engine will only store information on nodes that are within the subtree of this node
	// Thus, if DAO engine has the information it means that I will be headed down from this point
      }else{
	// either I don't know where this packet is headed to or this is headed to the dodag root
	printfUART("Default Route Request! \n");
	*next_hop = call Routing.getNextHop(hdr->ip6_dst);
      }
    } 

    if(&hdr->ip6_plen == 0){
      // there was an error in finding the next hop
      printfUART("No Next Hop! \n");
      return FAIL;
    }    
    return SUCCESS;
  }

  bool loopDetect(bool o_bit, uint16_t rank){

    // o bit and previous rank based loop detection!

    if(rank == 0){
      // this is only the first hop
      return FALSE;
    }

    if(o_bit && rank > call Routing.getRank()){
      // downwards
      return TRUE;
    }else if(!o_bit && rank < call Routing.getRank()){
      // upwards inconsistency
      return TRUE;
    }
    return FALSE; // no loop
  }

  command error_t IP.send[uint8_t nxt_hdr](struct ip6_packet *pkt) {

    struct in6_addr next_hop_local;
    struct ieee154_frame_addr addr_struct;
    struct rpl_route routing_hdr;
    uint8_t o_bit = 0;

    if(!call Routing.hasDODAG()){
      return EOFF;
    }

    pkt->ip6_hdr.ip6_nxt = nxt_hdr;

    call IPAddress.getLLAddr(&local_addr);

    memcpy(&pkt->ip6_hdr.ip6_src, &local_addr, 16);

    memcpy(&next_hop_local, &pkt->ip6_hdr.ip6_dst, sizeof(struct in6_addr));

    getNextHop(&pkt->ip6_hdr, &routing_hdr, &next_hop_local, &pkt->ip6_data, o_bit);
    initPacket(&pkt->ip6_hdr, &next_hop_local);

    addr_struct.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;
    addr_struct.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;
    addr_struct.ieee_dstpan = TOS_AM_GROUP;

    call IPAddress.resolveAddress(&next_hop_local, &addr_struct.ieee_dst);
    call IPAddress.resolveAddress(&local_addr, &addr_struct.ieee_src);

    pkt->ip6_hdr.ip6_vfc = IPV6_VERSION;

    if(next_hop_local.s6_addr16[7] == htons(0)){ // invalid address
      return FAIL; 
    }

    printfUART(">> DATA TX %d ADDR %d %d \n", pkt->ip6_hdr.ip6_vfc, addr_struct.ieee_dst.i_saddr, addr_struct.ieee_src.i_saddr);

    return call RPLForwardingSend.sendPacket(&addr_struct, pkt, (void*) &next_hop_local);
  }


  event void RPLForwardingSend.recvPacket(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta){
    struct ieee154_frame_addr addr_struct;
    struct rpl_route routing_hdr;
    struct in6_addr next_hop;
    struct ip6_packet pkt;
    struct ip6_ext *cur = (struct ip6_ext *)payload;
    uint8_t nxt = iph->ip6_nxt;
    struct ip_iovec v;
    uint8_t i;
    ip_first_hdr_t *flow_hdr = (ip_first_hdr_t*) &iph->ip6_flow;
#ifndef RPL_STORING_MODE
    struct rpl_route* r_hdr;
    uint8_t r_hdr_length;
#endif
    //1) DEAL WITH PACKETS THAT I NEED TO FORWARD! CHECK FORWARDING RULES!! // HEADER MODIFICATIONS?

    //filter out packets by ip destination and others should go to the forwarding process

    if(call IPAddress.isLocalAddress(&iph->ip6_src)){
      // should not happen!
      printfUART("My Packet Came Back! \n");
      return;
    }

    if(call IPAddress.isLocalAddress(&iph->ip6_dst)){
      //call Leds.led2Toggle();
      while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
	     nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
	nxt = cur->ip6e_nxt;
	cur = cur + cur->ip6e_len;
      }

#ifndef RPL_STORING_MODE
      if(flow_hdr->o_bit && call Routing.getMOP() != RPL_MOP_No_Downward){
	// this packet should have a routing header
	r_hdr = (struct rpl_route*)payload;
	r_hdr_length = (r_hdr->hdr_ext_len * sizeof(struct in6_addr)) + 8;
	printfUART("FINAL RX from %d %d %d %d \n", ntohs(iph->ip6_src.s6_addr16[7]), flow_hdr->o_bit, r_hdr_length, sizeof(struct rpl_route));
	signal IP.recv[nxt](iph, (uint8_t*)payload+r_hdr_length, ntohs(iph->ip6_plen)-((void *)cur - payload)-r_hdr_length, meta);
      }else{
	// no routing header
	printfUART("FINAL RX from %d %d \n", ntohs(iph->ip6_src.s6_addr16[7]), flow_hdr->o_bit);
	signal IP.recv[nxt](iph, cur, ntohs(iph->ip6_plen)-((void *)cur - payload), meta);
      }
#else
      //no routing header;
      printfUART("FINAL RX from %d %d \n", ntohs(iph->ip6_src.s6_addr16[7]), flow_hdr->o_bit);
      signal IP.recv[nxt](iph, cur, ntohs(iph->ip6_plen)-((void *)cur - payload), meta);
#endif
      return;
    }else{

      printfUART("RX len %d \n", ntohs(iph->ip6_plen));

      if(loopDetect(flow_hdr->o_bit, flow_hdr->senderRank)){
	//there is an inconsistency
	if(flow_hdr->r_bit){
	  // this is not the first time dude!
	  // ditch this packet!
	  return;
	}else{
	  flow_hdr->r_bit = 1;
	  // proceed!
	}
      }

      if(!(--iph->ip6_hlim)){
	// no more hops to go!
	return;
      }

      // at this point I have decied to send the packet
      flow_hdr->senderRank = call Routing.getRank();

      // get next hop again / send away 

      if(getNextHop(iph, &routing_hdr, &next_hop, payload, flow_hdr->o_bit) == SUCCESS){

	printfUART("next hop %d %d\n", next_hop.s6_addr16[7], ntohs(next_hop.s6_addr16[7]));

	for(i=0;i<8;i++){
	  printfUART("%x ", ntohs(next_hop.s6_addr16[i]));
	}

	printfUART("\n")

	if(call RPLRank.getRank(next_hop) < call Routing.getRank()){
	  // this packet is headed downwards!
	  flow_hdr->o_bit = 0;
	}else{
	  // this packet is headed upwards!
	  flow_hdr->o_bit = 1;
	}

	addr_struct.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;
	addr_struct.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;
	addr_struct.ieee_dstpan = TOS_AM_GROUP;

	call IPAddress.resolveAddress(&next_hop, &addr_struct.ieee_dst);

	call IPAddress.getLLAddr(&local_addr);

	call IPAddress.resolveAddress(&local_addr, &addr_struct.ieee_src);

	if(next_hop.s6_addr16[7] == htons(0)){
	  return;
	}

	memset(&pkt, 0, sizeof(pkt));
	memcpy(&pkt.ip6_hdr, iph, sizeof(struct ip6_hdr));

	pkt.ip6_data = &v;

	v.iov_next = NULL;
	v.iov_base = payload;
	v.iov_len  = ntohs(iph->ip6_plen) - ((void *)cur - payload);

	pkt.ip6_hdr.ip6_plen = ntohs(iov_len(&v));
	
	printfUART(">> FWDTX ADDR %d %d %d %d\n", addr_struct.ieee_dst.i_saddr, addr_struct.ieee_src.i_saddr, ntohs(pkt.ip6_hdr.ip6_src.s6_addr16[7]), htons(pkt.ip6_hdr.ip6_plen));

	call RPLForwardingSend.sendPacket(&addr_struct, &pkt, &next_hop);
      }
    }
  }

  command struct in6_addr* Fwd.getDefaultDodagId(){
    call IPAddress.getLLAddr(&local_addr);
    return &local_addr;
  }

  event void RPLRank.parentRankChange(){
  }

 default event void IP.recv[uint8_t nxt_hdr](void *iph, void *payload, size_t len, struct ip6_metadata *meta) {}
}
