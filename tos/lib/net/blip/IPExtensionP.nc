
/* 
 * Provides various functions for dealing with IP extension header
 * processing

 *
 */

#include <ip_malloc.h>

module IPExtensionP {
  provides {
    // for inserting destination and hop-by-hop headers on outgoing packets.
    // routing headers are handled through the IPRouting interface
    interface Init;
    interface TLVHeader as HopByHopExt[uint8_t client];
    interface TLVHeader as DestinationExt[uint8_t client];
    interface InternalIPExtension;
  }
} implementation {

  struct generic_header *ext_dest, *ext_hop;

  command error_t Init.init() {
    ext_hop = ext_dest = NULL;
    return SUCCESS;
  }

  struct tlv_hdr *destopt_get(int i, int nxt_hdr, struct ip6_hdr *iph) {
    return signal DestinationExt.getHeader[i](0, nxt_hdr, iph);
  }
  struct tlv_hdr *hopopt_get(struct ip6_hdr *iph, int i) { //, uint8_t nxt_hdr) {
    // return signal HopByHopExt.getHeader[i](label, iph, nxt_hdr);
    return NULL;
  }

  /* build up a sequence of TLV headers for hop-by-hop or
     destination only extension headers */
  struct generic_header *buildTLVHdr(struct split_ip_msg *msg,
                                     int which, 
                                     int n, int nxt_hdr) {
    // allocate generic headers for all the possible TLV-encoded
    // headers we might get
    int i;
    uint8_t *buf = ip_malloc(sizeof(struct ip6_ext) + (sizeof(struct generic_header) * (n + 1)));
    struct ip6_ext *real_hdr;
    struct generic_header *ghdrs;
    if (buf == NULL) return NULL;
    ghdrs = (struct generic_header *)buf;
    real_hdr = (struct ip6_ext *)(ghdrs + (n + 1));


    real_hdr->len = sizeof(struct ip6_ext);

    ghdrs[0].len = sizeof(struct ip6_ext);
    ghdrs[0].hdr.data = (uint8_t *)real_hdr;
    ghdrs[0].next = msg->headers;

    for (i = 0; i < n; i++) {
      struct tlv_hdr *this_hdr;
      if (which == 0) {
        printfUART("adding destination idx %i\n", i);
        this_hdr = signal DestinationExt.getHeader[i](0, nxt_hdr, &msg->hdr);
      } else {
        this_hdr = signal HopByHopExt.getHeader[i](0, nxt_hdr, &msg->hdr);
      }

      printfUART("buildTLV: got %p\n", this_hdr);
      if (this_hdr == NULL) continue;

      real_hdr->len += this_hdr->len;
      ghdrs[i+1].len = this_hdr->len;
      ghdrs[i+1].hdr.data = (uint8_t *)this_hdr;
      ghdrs[i].next = &ghdrs[i+1];
      ghdrs[i+1].next = msg->headers;
    }
    if (real_hdr->len == sizeof(struct ip6_ext)) {
      ip_free(buf);
      return NULL;
    } else {
      real_hdr->nxt_hdr = msg->hdr.nxt_hdr;
      msg->headers = ghdrs;
      return ghdrs;
    }
  }

  command void InternalIPExtension.addHeaders(struct split_ip_msg *msg, 
                                              uint8_t nxt_hdr,
                                              uint16_t label) {

    ext_dest = ext_hop = NULL;
    msg->hdr.nxt_hdr = nxt_hdr;
    ext_dest = buildTLVHdr(msg, 0, 1, nxt_hdr);
    if (ext_dest != NULL) msg->hdr.nxt_hdr = IPV6_DEST;

    ext_hop = buildTLVHdr(msg, 1, 1, msg->hdr.nxt_hdr);
    if (ext_hop != NULL) msg->hdr.nxt_hdr = IPV6_HOP;
  }

  command void InternalIPExtension.free() {
    if (ext_dest != NULL) ip_free(ext_dest);
    if (ext_hop  != NULL) ip_free(ext_hop);
    ext_dest = ext_hop = NULL;
    // signal HopByHopExt.free[0]();
    // signal DestinationExt.free[0]();
  }

#if 0
  void ip_dump_msg(struct split_ip_msg *msg) {
    struct generic_header *cur = msg->headers;
    int i;
    printfUART("DUMPING IP PACKET\n ");
    for (i = 0; i < sizeof(struct ip6_hdr); i++)
      printfUART("0x%x ", ((uint8_t *)&msg->hdr)[i]);
    printfUART("\n");

    while (cur != NULL) {
      printfUART(" header [%i]: ", cur->len);
      for (i = 0; i < cur->len; i++) 
        printfUART("0x%x ", cur->hdr.data[i]);
      printfUART("\n");
      cur = cur->next;
    }

    printfUART("data [%i]: ", msg->data_len);
    for (i = 0; i < msg->data_len; i++) 
      printfUART("0x%x ", ((uint8_t *)msg->data)[i]);
    printfUART("\n\n");
  }
#endif

  default event struct tlv_hdr *DestinationExt.getHeader[uint8_t i](int label,int nxt_hdr,
                                                                   struct ip6_hdr *msg) {
    printfUART("default dest handler?\n");
    return NULL;
  }

  default event struct tlv_hdr *HopByHopExt.getHeader[uint8_t i](int label,int nxt_hdr,
                                                                   struct ip6_hdr *msg) {
    return NULL;
  }


}
