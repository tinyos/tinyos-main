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

uint8_t buf[512];
struct ip_iovec vec[1];
struct ip6_ext *ext;
struct tlv_hdr *tlv;

int main() {
  int success = 0, total = 0;
  uint8_t rv;
  ext = (struct ip6_ext *)buf;
  vec->iov_base = buf;
  vec->iov_len = 512;

  /* test 1 */
  {
    total ++;
    printf("starting test 1\n");
    ext->ip6e_len = 0;
    ext->ip6e_nxt = 0;
    rv = __ipnh_real_length(IPV6_ROUTING, vec, 0);
    if (rv == 8)
      success ++;
    else
      fprintf(stderr,"FAIL: test 1: %i\n", rv);
  }

  /* test 2 */
  {
    /* HBH header with all pad 1 options */
    total ++;
    printf("starting test 2\n");
    memset(buf, 0, 8);          /* len = 0 nxt = 0 6x pad1 options */
    rv = __ipnh_real_length(IPV6_HOP, vec, 0);
    if (rv == 2) {
      success ++;
    } else {
      printf("FAIL: test 2: %i\n", rv);
    }
  }

  /* test 3 */
  {
    total++;
    printf("starting test 3\n");
    memset(buf, 0, 8);
    tlv = ext + 1;
    tlv->type = IPV6_TLV_PADN;
    tlv->len = 4;
    rv = __ipnh_real_length(IPV6_HOP, vec, 0);
    if (rv == 2) 
      success ++;
    else
      fprintf(stderr, "FAIL: test 3: %i\n", rv);
  }

  /* test 4 */
  {
    /* one TLV encoded payload with length 4 */
    total++;
    printf("starting test 4\n");
    memset(buf, 0, 8);
    tlv = ext + 1;
    tlv->type = 47;
    tlv->len = 4;
    rv = __ipnh_real_length(IPV6_HOP, vec, 0);
    if (rv == 8) 
      success ++;
    else {
      fprintf(stderr, "FAIL: test 4: %i\n", rv);
    }
  }

  {
    /* one TLV encoded payload with length 11 + Pad1 */
    total++;
    printf("starting test 5\n");
    memset(buf, 0, 16);
    ext->ip6e_len = 1;
    tlv = ext + 1;
    tlv->type = 47;
    tlv->len = 11;
    rv = __ipnh_real_length(IPV6_HOP, vec, 0);
    if (rv == 15) 
      success ++;
    else {
      fprintf(stderr, "FAIL: test 5: %i\n", rv);
    }
  }


  {
    /* one TLV encoded payload with length 11 + Pad1 + tlv length 8*/
    total++;
    printf("starting test 6\n");
    memset(buf, 0, 24);
    ext->ip6e_len = 2;
    tlv = ext + 1;
    tlv->type = 47;
    tlv->len = 11;
    tlv = &buf[16];
    tlv->type = 48;
    tlv->len = 6;
    rv = __ipnh_real_length(IPV6_HOP, vec, 0);
    if (rv == 24) 
      success ++;
    else {
      fprintf(stderr, "FAIL: test 5: %i\n", rv);
    }
  }


  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
}
