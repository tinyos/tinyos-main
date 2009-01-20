/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include <stdint.h>
#include <stdio.h>
// #include <arpa/inet.h>
#include "6lowpan.h"
#include "lib6lowpan.h"
#include "lib6lowpanIP.h"


void printBuf(uint8_t *buf, uint16_t len) {
  int i;
  for (i = 1; i <= len; i++) {
    printf(" 0x%02x", buf[i-1]);
    if (i % 16 == 0) printf("\n");

  }
  printf("\n\n");
}


void printPacket(uint8_t *buf, int len) {
  uint8_t val;
  uint16_t origin, final;
  packed_lowmsg_t pkt;

  // used for autoconfiguration; would be provided by lower layers.
  pkt.src = 0xaa;
  pkt.dst = 0xbb;

  printBuf(buf, len);

  pkt.data = buf;
  pkt.len = len;
  pkt.headers = getHeaderBitmap(&pkt);
  printf("6loWPAN Packet (headers: 0x%x)\n", pkt.headers);
  if (hasBcastHeader(&pkt)) {
    getBcastSeqno(&pkt, &val);
    printf("   BCast seqno: 0x%x\n", val);
  }
  if (hasMeshHeader(&pkt)) {
    getMeshHopsLeft(&pkt, &val);
    getMeshOriginAddr(&pkt, &origin);
    getMeshFinalAddr(&pkt, &final);
    printf("   Mesh hops: 0x%x origin: 0x%x final: 0x%x\n", val, origin, final);
  }
  if (hasFrag1Header(&pkt) || hasFragNHeader(&pkt)) {
    getFragDgramSize(&pkt, &origin);
    getFragDgramTag(&pkt, &final);
    printf("   Frag size: 0x%x tag: 0x%x\n", origin, final);
  }
  if (hasFragNHeader(&pkt)) {
    getFragDgramOffset(&pkt, &val);
    printf("   Frag offset: 0x%x\n", val);
  }

  
  uint8_t data[100];
  struct ip6_hdr *h = (struct ip6_hdr *)data;
  unpackHeaders(&pkt, (uint8_t *)h, 100);

  printf(" ip first bytes: 0x%x\n", ntohl(*((uint32_t *)h->vlfc)));
  printf("   plen: 0x%x next: 0x%x hlim: 0x%x\n", ntohs(h->plen), h->nxt_hdr, h->hlim);
  printf("   src: ");
  for (val = 0; val < 16; val++)
    printf("0x%x ", h->src_addr[val]);
  printf("\n   dst: ");
  for (val = 0; val < 16; val++)
    printf("0x%x ", h->dst_addr[val]);
  printf("\n");

  if (h->nxt_hdr == IANA_UDP) {
    struct udp_hdr *udp = (struct udp_hdr *)&data[sizeof(struct ip6_hdr)];
    printf("udp src: 0x%x dst: 0x%x len: 0x%x cksum: 0x%x\n",
           ntoh16(udp->srcport), ntoh16(udp->dstport),
           ntoh16(udp->len), ntoh16(udp->chksum));
  }
           

  printf("\n\n");
}
