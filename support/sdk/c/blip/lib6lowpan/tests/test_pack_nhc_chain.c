#include <stdint.h>
#include <string.h>
#ifdef UNIT_TESTING
#include <stdio.h>
#endif

#include "6lowpan.h"
#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"



struct {
  uint8_t hdr[128];
} ip_hdrs[] = {
  {IPV6_DEST, 8,  0,1,2,3,4,5},
  {IANA_UDP,  10, 0,1,2,3,4,5,6,7},
};

struct udp_hdr udp = {0xabcd, 0x1234, 512, 0xdead};

struct ip6_packet packet;
struct ip_iovec vec[3];

int main() {
  uint8_t nxt;
  uint8_t buf[512], result[512], *bufp;
  int i, len;
  bufp = buf;
  packet.ip6_hdr.ip6_nxt = IPV6_HOP;
  
  iov_prefix(NULL, &vec[2], (uint8_t *)&udp, 8);
  iov_prefix(&vec[2], &vec[1], ip_hdrs[1].hdr, 10);
  iov_prefix(&vec[1], &vec[0], ip_hdrs[0].hdr, 8);

  packet.ip6_data = vec;

  len = pack_nhc_chain(&bufp, 512, &packet);
  printf("[%i] ", len);
  for (i = 0; i < len; i++) {
    printf("0x%hhx ", buf[i]);
  }
  printf("\n\n");

  unpack_nhc_chain(result, 512, &nxt, buf);
  for (i = 0; i < 26; i++)
    printf("0x%hhx ", result[i]);
  printf("\n");
  printf("Done!\n");
}
