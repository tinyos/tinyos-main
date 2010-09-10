
#include <ip.h>
#include <PrintfUART.h>

#include "Statistics.h"
#include "ipmulticast.h"

#define MAX_MSG_COUNT 5 // only send multicast messages this many times

module MulticastP {
  provides {
    interface Init;
    interface IP[uint8_t nxt_hdr];
    interface Statistics<mcast_statistics_t>;
  }

  uses  {
    interface IP as MulticastRx[uint8_t nxt_hdr];
    interface TLVHeader as HopHeader;
    interface TrickleTimer;
    interface IPExtensions;
  }
} implementation {
  
  bool trickle_running;
  uint16_t last_seqno;
  uint8_t fw_hdr;  
  struct split_ip_msg fw_msg;
  uint8_t fw_data[MCAST_FW_MAXLEN];
  int fw_data_len;
  uint8_t msg_count;

  command error_t Init.init() {
    last_seqno = 0;
    return SUCCESS;
  }

  void startNewMsg(struct ip6_hdr *iph, uint8_t nxt_hdr) {

    // store a copy of the message for forwarding
    ip_memclr((void *)&fw_msg, sizeof(struct split_ip_msg));
    ip_memcpy(&fw_msg.hdr, iph, sizeof(struct ip6_hdr));

    fw_hdr = nxt_hdr;
    fw_msg.headers = NULL;
    fw_msg.data = fw_data;
    fw_msg.data_len = fw_data_len;
    msg_count = 0;

//	printfUART("MCAST: startNewMsg\n");
    call TrickleTimer.stop();
    call TrickleTimer.reset();
    call TrickleTimer.start();

  }

  /*
   * receive all IP datagrams.
   * we store and forward ones with scope 3
   */
  event void MulticastRx.recv[uint8_t nxt_hdr](struct ip6_hdr *iph, 
                                               void *payload, 
                                               struct ip_metadata *meta) {
    struct ip6_ext *hop;
    struct tlv_hdr *mcast_tlv;
    struct mcast_hdr *mcast;
    // no sequence number attached?

//    printfUART("MCAST: recv\n");

    if (iph->nxt_hdr != IPV6_HOP) {
      goto deliver;
    }
    hop = (struct ip6_ext *)(iph + 1);
    mcast_tlv = call IPExtensions.findTlv(hop, TLV_TYPE_MCASTSEQ);
    mcast = (struct mcast_hdr *)mcast_tlv;
    // no mcast sequence number?
    if (mcast == NULL) {
      goto deliver;
    }

    if (ntohs(mcast->mcast_seqno) > last_seqno || 
        (last_seqno > 0xfff0 && ntohs(mcast->mcast_seqno) < 0x0f)) {
      uint16_t length = ntohs(iph->plen);
      if (length < MCAST_FW_MAXLEN) {
//        printfUART("MCAST: seqno was: %i now: %i\n", last_seqno, ntohs(mcast->mcast_seqno));
        last_seqno = ntohs(mcast->mcast_seqno);
        memcpy(fw_data, payload, length);
        fw_data_len = length;

        startNewMsg(iph, nxt_hdr);

//        printfUART("MCAST: starting new mcast message seqno: %i\n", last_seqno);
      }
      goto deliver;
    } else if (ntohs(mcast->mcast_seqno) == last_seqno &&
               memcmp(iph->ip6_src.s6_addr, fw_msg.hdr.ip6_src.s6_addr, 16) == 0) {
      // received a retranmission.  just update the trickle timer.
//	  printfUART("MCAST: received consistent transmission, seqno: %d\n", ntohs(mcast->mcast_seqno));
      call TrickleTimer.incrementCounter();
    }
    return;
  deliver:
    signal IP.recv[nxt_hdr](iph, payload, meta);
  }

  /* 
   * add sequence numbers to outgoing multicast packets so we can
   * detect when there are new ones.
   */
  event struct tlv_hdr *HopHeader.getHeader(int label,int nxt_hdr,
                                            struct ip6_hdr *iph) {
    // only add sequence number headers to outgoing flood messages
    static struct mcast_hdr hdr;
    if (iph->ip6_dst.s6_addr16[0] != htons(0xff03))  return NULL;
//    printfUART("MCAST: adding multicast header, seqno: %d\n",last_seqno);

    hdr.tlv.type = TLV_TYPE_MCASTSEQ;
    hdr.tlv.len = sizeof(struct mcast_hdr);
    hdr.mcast_seqno = htons(last_seqno);
    return (struct tlv_hdr *)&hdr;
  }

  event void HopHeader.free() {}

  event void TrickleTimer.fired() {
    // it's that easy... the sequence number will get added when
    // outgoing headers are added.
    fw_msg.headers = NULL;
    fw_msg.hdr.nxt_hdr = fw_hdr;
    fw_msg.hdr.plen = htons(fw_data_len);
    fw_msg.data_len = fw_data_len;
    call MulticastRx.bareSend[fw_hdr](&fw_msg, NULL, IP_MCAST);

    msg_count = msg_count + 1;
    if (msg_count >= MAX_MSG_COUNT) {
      msg_count = 0;
      call TrickleTimer.stop();
    }
  }

  command error_t IP.send[uint8_t nxt_hdr](struct split_ip_msg *msg) {
    
    if (msg->hdr.ip6_dst.s6_addr[0] == 0xff) {
      if ((msg->hdr.ip6_dst.s6_addr[1] & 0x0f) == 0x3) {
        int total_length = ntohs(msg->hdr.plen);
        unsigned char *cur = fw_data;
        struct generic_header *g_hdr;

        if (total_length > MCAST_FW_MAXLEN) return FAIL;

        last_seqno++;
        startNewMsg(&msg->hdr, nxt_hdr);
        
        fw_data_len = total_length;
        g_hdr = msg->headers;
        while (g_hdr != NULL) {
          total_length -= g_hdr->len;
          if (total_length < 0) goto fail;
          memcpy(cur, g_hdr->hdr.data, g_hdr->len);
          cur +=g_hdr->len;
          g_hdr = g_hdr->next;
        }
        if (msg->data_len > total_length) goto fail;
        memcpy(cur, msg->data, msg->data_len);

        return SUCCESS;
      fail:
        call TrickleTimer.stop();
        return FAIL;

      } else {
        return call MulticastRx.bareSend[nxt_hdr](msg, NULL, IP_MCAST);
      }
    }
    return SUCCESS;
  }
  command error_t IP.bareSend[uint8_t prot](struct split_ip_msg *msg,
                                            struct ip6_route *route,
                                            int flags) {
    if (msg->hdr.ip6_dst.s6_addr[0] == 0xff) {
      return call MulticastRx.bareSend[prot](msg, route, flags | IP_MCAST);
    } else {
      return SUCCESS;
    }
  }

  event void IPExtensions.reportTransmission(uint8_t label, send_policy_t *policy) {

  }
  event void IPExtensions.handleExtensions(uint8_t label,
                                           struct ip6_hdr *iph,
                                           struct ip6_ext *hop,
                                           struct ip6_ext *dst,
                                           struct ip6_route *route,
                                           uint8_t nxt_hdr) {
  }
  default event void IP.recv[uint8_t nxt_hdr](struct ip6_hdr *iph,
                                              void *payload,
                                              struct ip_metadata *meta) {
  }

  command void Statistics.get(mcast_statistics_t *stats) {
    stats->lsn = last_seqno;
  }
  
  /*
   * Reset whatever statistics are being collected.
   */
  command void Statistics.clear() {}

}
