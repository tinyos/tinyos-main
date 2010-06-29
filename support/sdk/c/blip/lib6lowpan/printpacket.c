/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 * - Neither the name of the copyright holders nor the names of
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
