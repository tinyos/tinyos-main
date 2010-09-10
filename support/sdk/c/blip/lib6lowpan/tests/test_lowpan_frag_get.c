

#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"
#include "iovec.h"



uint8_t ctx[8] = {0x20, 0x02,1,2,3,4,5,6};

int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  memcpy(addr, ctx, 8);
  return 64;
}

int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
  if (memcmp(addr, ctx, 8) == 0) {
    printf("CONTEXT MATCH!\n");
    return 64;
  } else {
    return 0;
  }
}


struct test_case {
  uint8_t  tc;
  uint32_t fl;
  uint8_t  nxt;
  uint8_t  hlim;
  char *ip6_src;
  char *ip6_dst;

  char *l2src, *l2dst;
  ieee154_panid_t   panid;

  /*  the result of executing the test case */
  int      result_len;
  uint8_t  result[64];
};

struct test_case cases[] = {
  {0, 0, IANA_UDP, 66, "fe80::1", "ff02::1", "1", "aa:00:11:22:33:44:55:66:", 0xabcd, 
   0, {}},

  {1, 0, IANA_UDP, 100, "fe80::1", "fe80::2", "1", "65535", 10, 
   0, {}},

  {0, 0, IANA_UDP, 100, "fe80::aa00:1122:3344:5566", "ff02::ab", "aa:00:11:22:33:44:55:66:", "0xab", 10, 0, {}},

  {0, 0, IANA_UDP, 100, "2002:102:304:506:aa00:1122:3344:5566", "ff02::12:4567:abcd", "aa:00:11:22:33:44:55:66:", "0xab", 10, 0, {}},

};

uint8_t data[12] = {1,2,3,4,5,6,7,8,9,10,11,12};

int check_test(struct ip6_packet *pkt, struct lowpan_reconstruct *recon) {
  char buf[2048];
  memset(buf, 0, 2048);
  memcpy(buf, &pkt->ip6_hdr, sizeof(struct ip6_hdr));
  iov_read(pkt->ip6_data, 0, iov_len(pkt->ip6_data), &buf[sizeof(struct ip6_hdr)]);
  
  // printf("CMP: %i", memcmp(buf, recon->r_buf, recon->r_bytes_rcvd));
  print_buffer(buf, 50);
  print_buffer(recon->r_buf, 50);
  printf("CMP: %i\n", memcmp(buf, recon->r_buf, 50));
}

void setup_test(struct test_case *cse, struct ip6_hdr *hdr, struct ieee154_frame_addr *frame, struct ip_iovec *v) {
  uint32_t val;

  printf("packet length: %i, %p\n", iov_len(v), v);

  val = htonl(0x6 << 28 | ((cse->tc & 0xff) << 20) | (cse->fl & 0x000fffff));
  hdr->ip6_flow = val;
  hdr->ip6_nxt  = cse->nxt;
  hdr->ip6_plen = htons(iov_len(v));
  hdr->ip6_hlim = cse->hlim;
  inet_pton6(cse->ip6_src, &hdr->ip6_src);
  inet_pton6(cse->ip6_dst, &hdr->ip6_dst);

  memset(frame, 0, sizeof(frame));
  ieee154_parse(cse->l2src, &frame->ieee_src);
  ieee154_parse(cse->l2dst, &frame->ieee_dst);
  frame->ieee_dstpan = htole16(cse->panid);
}

int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(cases) / sizeof(cases[0])); i++) {
    uint8_t buf[128], *rp, unpack[512], more_data[1500];
    struct ip6_packet packet;
    struct ieee154_frame_addr fr, result_fr;
    struct lowpan_reconstruct recon;
    struct lowpan_ctx ctx;
    struct ip_iovec v[2];
    int rv;
    memset(buf, 0, sizeof(buf));
    total++;
    printf("\n\n----- Test case %i ----\n", i+1);

    packet.ip6_data = &v[0];
    v[0].iov_next = &v[1];
    v[0].iov_base= data;
    v[0].iov_len = 12;
    for (rv = 0; rv < sizeof(more_data); rv++)
      more_data[rv] = rv;

    v[1].iov_next = NULL;
    v[1].iov_base= more_data;
    v[1].iov_len = 1500;
    // print_buffer(more_data, 1500);

    setup_test(&cases[i], &packet.ip6_hdr, &fr, &v[0]);

    printf("IEEE 802.15.4 frame: ");
    print_buffer(&fr, sizeof(struct ieee154_frame_addr));
    printf("\n");
    printf("IPv6 Header:\n");
    print_buffer(&packet.ip6_hdr, sizeof(struct ip6_hdr));
    printf("\n");
    printf("Data:\n");
    print_buffer(data, 12);
    printf("\n");
    printf("plen: %i\n", ntohs(packet.ip6_hdr.ip6_plen));

    ctx.offset = 0;
    ctx.tag = 25;
    recon.r_buf = NULL;

    /* how you fragment a packet */
    while ((rv = lowpan_frag_get(buf, sizeof(buf),
                                 &packet,
                                 &fr,
                                 &ctx)) > 0) {
      // print_buffer(buf, rv);

      /* how you unfragment a packet */
      rp = unpack_ieee154_hdr(buf, &result_fr);
      printf("unpacked ieee154_header: %p-%p\n", buf, rp);
      // print_buffer(&result_fr, sizeof(result_fr));

      if (recon.r_buf == NULL) {
        lowpan_recon_start(&result_fr, &recon, rp, rv - (rp - buf));
      } else {
        lowpan_recon_add(&recon, rp, rv - (rp - buf));
      }
      memset(buf, 0, sizeof(buf));
    }
    printf("recon progress: %i %i\n", recon.r_bytes_rcvd, recon.r_size);

    print_buffer(recon.r_buf, recon.r_bytes_rcvd);
    if (recon.r_bytes_rcvd == recon.r_size) {
      if (check_test(&packet, &recon) == 0) {
        success++;
      }
    }

    free(recon.r_buf);
    recon.r_buf = NULL;

  }

  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
