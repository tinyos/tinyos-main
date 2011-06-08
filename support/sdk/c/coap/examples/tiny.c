/* tiny -- tiny sender
 *
 * Copyright (C) 2010 Olaf Bergmann <bergmann@tzi.org>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <limits.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "../coap.h"

static coap_tid_t id;

coap_pdu_t *
make_pdu( unsigned int value ) {
  coap_pdu_t *pdu;
  unsigned char enc;
  static unsigned char buf[20];
  int len, ls;

  if ( ! ( pdu = coap_new_pdu() ) )
    return NULL;

  pdu->hdr->type = COAP_MESSAGE_NON;
  pdu->hdr->code = COAP_REQUEST_POST;
  pdu->hdr->id = htons(id++);

  enc = COAP_PSEUDOFP_ENCODE_8_4_DOWN(value,ls);
  coap_add_data( pdu, 1, &enc);

  len = sprintf((char *)buf, "%u", COAP_PSEUDOFP_DECODE_8_4(enc));
  if ( len > 0 ) {
    coap_add_data( pdu, len, buf );
  }

  return pdu;
}

void 
usage( const char *program ) {
  const char *p;

  p = strrchr( program, '/' );
  if ( p )
    program = ++p;

  fprintf( stderr, "%s -- tiny fake sensor\n"
	   "(c) 2010 Olaf Bergmann <bergmann@tzi.org>\n\n"
	   "usage: %s [group address]\n"
	   "\n\nSends some fake sensor values to specified multicast group\n",
	   program, program );
}

int 
main(int argc, char **argv) {
  coap_context_t  *ctx;
  struct timeval tv;
  coap_pdu_t  *pdu;
  struct sockaddr_in6 dst;
  int hops = 16;

  if ( argc > 1 && strncmp(argv[1], "-h", 2) == 0 ) {
    usage( argv[0] );
    exit( 1 );
  }

  ctx = coap_new_context(0);
  if ( !ctx )
    return -1;
  id = rand() & INT_MAX;

  memset(&dst, 0, sizeof(struct sockaddr_in6 ));
  dst.sin6_family = AF_INET6;
  inet_pton( AF_INET6, argc > 1 ? argv[1] : "::1", &dst.sin6_addr );
  dst.sin6_port = htons( COAP_DEFAULT_PORT );

  if ( IN6_IS_ADDR_MULTICAST(&dst.sin6_addr) ) {
    /* set socket options for multicast */ 

    if ( setsockopt( ctx->sockfd, IPPROTO_IPV6, IPV6_MULTICAST_HOPS,
		     (char *)&hops, sizeof(hops) ) < 0 )
      perror("setsockopt: IPV6_MULTICAST_HOPS");

  }

  while ( 1 ) {
    
    if (! (pdu = make_pdu( rand() & 0xfff ) ) )
      return -1;

    coap_send( ctx, &dst, pdu );

    tv.tv_sec = 5; tv.tv_usec = 0;

    select( 0, 0, 0, 0, &tv );
    
  }

  coap_free_context( ctx );

  return 0;
}
