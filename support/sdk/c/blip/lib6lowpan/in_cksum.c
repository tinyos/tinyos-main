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
/* in_cksum.c
 * 4.4-Lite-2 Internet checksum routine, modified to take a vector of
 * pointers/lengths giving the pieces to be checksummed.
 *
 * $Id: in_cksum.c,v 1.2 2009-08-09 23:36:06 sdhsdh Exp $
 */

/*
 * Copyright (c) 1988, 1992, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *      @(#)in_cksum.c  8.1 (Berkeley) 6/10/93
 */

#include <stdlib.h>
#include "in_cksum.h"
#include "lib6lowpan.h"


#define ADDCARRY(x)  (x > 65535 ? x -= 65535 : x)
#define REDUCE {l_util.l = sum; sum = l_util.s[0] + l_util.s[1]; ADDCARRY(sum);}

int
in_cksum(const vec_t *vec, int veclen) {

  uint32_t sum = 0;
  uint16_t res = 0;
  uint16_t cur = 0;
  int i;


  uint8_t *w;
 
  for (; veclen != 0; vec++, veclen--) {
    if (vec->len == 0)
      continue;
   
    w = (uint8_t *)vec->ptr;
    for (i = 0; i < vec->len; i++) {
      if (i % 2 == 0) {
        cur |= ((uint16_t)w[i]) << 8;
        if (i + 1 == vec->len) {
          goto finish;
        }
      } else {
        cur |= w[i];
      finish:
        sum += cur;
        res = (sum & 0xffff) + (sum >> 16);
        cur = 0;
      }
    }
  }
  return ~res ;
#if 0
	register const uint16_t *w;
	register uint32_t sum = 0;
	register uint32_t mlen = 0;
	int byte_swapped = 0;

	union {
		uint8_t	c[2];
		uint16_t	s;
	} s_util;
	union {
		uint16_t s[2];
		uint32_t	l;
	} l_util;

	for (; veclen != 0; vec++, veclen--) {
		if (vec->len == 0)
			continue;
		w = (const uint16_t *)vec->ptr;
		if (mlen == -1) {
			/*
			 * The first byte of this chunk is the continuation
			 * of a word spanning between this chunk and the
			 * last chunk.
			 *
			 * s_util.c[0] is already saved when scanning previous
			 * chunk.
			 */
			s_util.c[1] = *(const uint8_t *)w;
			sum += s_util.s;
			w = (const uint16_t *)((const uint8_t *)w + 1);
			mlen = vec->len - 1;
		} else
			mlen = vec->len;
		/*
		 * Force to even boundary.
		 */
		if ((1 & (int) w) && (mlen > 0)) {
			REDUCE;
			sum <<= 8;
			s_util.c[0] = *(const uint8_t *)w;
			w = (const uint16_t *)((const uint8_t *)w + 1);
			mlen--;
			byte_swapped = 1;
		}
		/*
		 * Unroll the loop to make overhead from
		 * branches &c small.
		 */
		while ((mlen -= 32) >= 0) {
			sum += w[0]; sum += w[1]; sum += w[2]; sum += w[3];
			sum += w[4]; sum += w[5]; sum += w[6]; sum += w[7];
			sum += w[8]; sum += w[9]; sum += w[10]; sum += w[11];
			sum += w[12]; sum += w[13]; sum += w[14]; sum += w[15];
			w += 16;
		}
		mlen += 32;
		while ((mlen -= 8) >= 0) {
			sum += w[0]; sum += w[1]; sum += w[2]; sum += w[3];
			w += 4;
		}
		mlen += 8;
		if (mlen == 0 && byte_swapped == 0)
			continue;
		REDUCE;
		while ((mlen -= 2) >= 0) {
			sum += *w++;
		}
		if (byte_swapped) {
			REDUCE;
			sum <<= 8;
			byte_swapped = 0;
			if (mlen == -1) {
				s_util.c[1] = *(const uint8_t *)w;
				sum += s_util.s;
				mlen = 0;
			} else
				mlen = -1;
		} else if (mlen == -1)
			s_util.c[0] = *(const uint8_t *)w;
	}
	if (mlen == -1) {
		/* The last mbuf has odd # of bytes. Follow the
		   standard (the odd byte may be shifted left by 8 bits
		   or not as determined by endian-ness of the machine) */
		s_util.c[1] = 0;
		sum += s_util.s;
	}
	REDUCE;
	return (~sum & 0xffff);
#endif
}

/* SDH : Added to allow for friendly message checksumming */
uint16_t msg_cksum(struct split_ip_msg *msg, uint8_t nxt_hdr) {
  struct generic_header *cur;
  int n_headers = 4;
  vec_t cksum_vec[7];
  uint32_t hdr[2];

  cksum_vec[0].ptr = (uint8_t *)(msg->hdr.ip6_src.s6_addr);
  cksum_vec[0].len = 16;
  cksum_vec[1].ptr = (uint8_t *)(msg->hdr.ip6_dst.s6_addr);
  cksum_vec[1].len = 16;
  cksum_vec[2].ptr = (uint8_t *)hdr;
  cksum_vec[2].len = 8;
  hdr[0] = msg->data_len;
  hdr[1] = htonl(nxt_hdr);
  cksum_vec[3].ptr = msg->data;
  cksum_vec[3].len = msg->data_len;

  cur = msg->headers;
  while (cur != NULL) {
    cksum_vec[n_headers].ptr = cur->hdr.data;
    cksum_vec[n_headers].len = cur->len;
    hdr[0] += cur->len;
    n_headers++;
    cur = cur->next;
  }
  hdr[0] = htonl(hdr[0]);
  
  return in_cksum(cksum_vec, n_headers);
}
