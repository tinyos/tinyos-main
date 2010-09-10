
#include "TrackFlows.h"

module TrackFlowsP {
  uses {
    interface Boot;
    interface SplitControl as SerialControl;
    interface IPExtensions;
    interface TLVHeader as Headers;
    interface AMSend as FlowSend;
  }
} implementation {
  

  bool flow_send_busy = FALSE;
  uint16_t current_flowid = 0;
  message_t flow_send;

  int send_flow_idx = -1, cur_idx = 0;
  nx_struct {
    nx_uint8_t flags;
    nx_uint8_t label;
    nx_struct flow_id_msg flow;
  } flow_cache[N_FORWARD_ENT * 3];

  int get_entry() {
    cur_idx = (cur_idx + 1) % (N_FORWARD_ENT * 3);
    return cur_idx;
  }
  int lookup_entry(uint8_t label) {
    int i;
    for (i = 0; i < N_FORWARD_ENT * 3; i++) {
      if (flow_cache[i].flags == 1 && flow_cache[i].label == label)
        return i;
    } 
    return -1;
  }
  
  event void Boot.booted() {
    call SerialControl.start();
    flow_send_busy = FALSE;
    ip_memclr((void *)flow_cache, sizeof(flow_cache));
  }

  event void FlowSend.sendDone(message_t *msg, error_t error) {
    flow_send_busy = FALSE;
    flow_cache[send_flow_idx].flags = 0;
  }

  void update_msg(struct ip6_hdr *iph, nx_struct flow_id *flow, uint8_t label, uint8_t nxt_hdr) {
    nx_struct flow_id_msg *payload;
    int i = get_entry();
    if (i < 0) return;
    flow_cache[i].flags = 1;
    flow_cache[i].label = label;
    payload = &flow_cache[i].flow;

    memcpy(&payload->flow, flow, sizeof(nx_struct flow_id));
    payload->src = ntohs(iph->ip6_src.s6_addr16[7]);
    payload->dst = ntohs(iph->ip6_dst.s6_addr16[7]);
    payload->local_address = TOS_NODE_ID;
    payload->nxt_hdr = nxt_hdr;
  }

  event void IPExtensions.handleExtensions(uint8_t label,
                                           struct ip6_hdr *iph,
                                           struct ip6_ext *hop,
                                           struct ip6_ext *dst,
                                           struct ip6_route *route,
                                           uint8_t nxt_hdr) {
    if (hop != NULL) {
      struct tlv_hdr *tlv = call IPExtensions.findTlv(hop, TLV_TYPE_FLOW);
      if (tlv != NULL && tlv->len == sizeof(struct tlv_hdr) + sizeof(nx_struct flow_id)) {
        update_msg(iph, (nx_struct flow_id *)(tlv + 1), label, nxt_hdr);
      }
    }
  }

  event void IPExtensions.reportTransmission(uint8_t label, send_policy_t *send) {
    int i, flow_idx = lookup_entry(label);
    nx_struct flow_id_msg *payload =
      (nx_struct flow_id_msg *)call FlowSend.getPayload(&flow_send, sizeof(nx_struct flow_id_msg));

    
    if (flow_idx < 0) return;
    memcpy(payload, &flow_cache[flow_idx].flow, sizeof(nx_struct flow_id_msg));


    payload->n_attempts = 0;
    for (i = 0; i < send->current && i < 3; i++) {
      // if (send->dest[i] == IEEE154_BROADCAST_ADDR) return;
      
      payload->attempts[i].next_hop = send->dest[i];
      payload->attempts[i].tx = send->retries;
    }
    if (i < 3) {
      payload->attempts[i].next_hop = send->dest[i];
      payload->attempts[i].tx = send->actRetries;
      i++;
    }
    payload->n_attempts = i;
    
    if (!flow_send_busy) {
      if (call FlowSend.send(0xffff, &flow_send, sizeof(nx_struct flow_id_msg)) == SUCCESS) {
        flow_send_busy = TRUE;
        send_flow_idx = flow_idx;
        return;
      } 
      // otherwise fall through and invalidate the cache
    }
    flow_cache[flow_idx].flags = 0;
  }

  event struct tlv_hdr *Headers.getHeader(uint8_t label,
                                          struct ip6_hdr *msg,
                                          uint8_t nxt_hdr) {
    static uint8_t buf[sizeof(struct tlv_hdr) + sizeof(nx_struct flow_id)];
    struct tlv_hdr *tlv;
    nx_struct flow_id *flow;
    tlv = (struct tlv_hdr *)buf;
    flow = (nx_struct flow_id *)(tlv + 1);

    tlv->type = TLV_TYPE_FLOW;
    tlv->len = sizeof(struct tlv_hdr) + sizeof(nx_struct flow_id);

/*     if (msg->ip6_dst.s6_addr[0] != 0xff ||  */
/*         (msg->ip6_dst.s6_addr[0] == 0xff &&  */
/*          (msg->ip6_dst.s6_addr[1] & 0x0f) > 2)) { */
      flow->id  = current_flowid++;

      update_msg(msg, flow, label, nxt_hdr);
      return tlv;
/*     } */
/*     return NULL; */
  }

  event void SerialControl.startDone(error_t e) { }
  event void SerialControl.stopDone(error_t e) { }

}
