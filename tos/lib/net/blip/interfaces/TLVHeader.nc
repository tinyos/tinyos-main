
#include <ip.h>

interface TLVHeader {
  event struct tlv_hdr *getHeader(int label,int nxt_hdr,
                                  struct ip6_hdr *msg);

  event void free();
}
