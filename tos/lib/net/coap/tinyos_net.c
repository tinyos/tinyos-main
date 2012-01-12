/*
 * Copyright (c) 2011 University of Bremen, TZI
 * All rights reserved.
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
 */

#include <tinyos_net.h>

int
coap_read(coap_context_t *ctx,
	  struct sockaddr_in6 *src, void *buf,
	  uint16_t bytes_read, struct ip6_metadata *meta) {
  coap_queue_t *node;
  coap_opt_t *opt;

  if ( bytes_read < 0 || bytes_read>=COAP_MAX_PDU_SIZE) {
    return -1;
  }

  if ( bytes_read < sizeof(coap_hdr_t) || ((coap_hdr_t *)buf)->version != COAP_DEFAULT_VERSION ) {
#ifndef NDEBUG
    //fprintf(stderr, "coap_read: discarded invalid frame\n" );
#endif
    return -1;
  }
  node = coap_new_node();
  if ( !node )
    return -1;

  node->pdu = coap_new_pdu();
  if ( !node->pdu ) {
    coap_delete_node( node );
    return -1;
  }

  /*printf("** coap: coap_read pointers %p %p, %p %p\n",
    &node->remote,
    node->remote,
    src,
    *src,
    sizeof(src),
    sizeof(*src));*/

  memcpy( &node->remote, src, sizeof( *src ) );

  /* "parse" received PDU by filling pdu structure */
  memcpy( node->pdu->hdr, buf, bytes_read );
  node->pdu->length = bytes_read;

  /* finally calculate beginning of data block */
  options_end( node->pdu, &opt );

  if ( (unsigned char *)node->pdu->hdr + node->pdu->length <
       (unsigned char *)opt )
    node->pdu->data = (unsigned char *)node->pdu->hdr + node->pdu->length;
  else
    node->pdu->data = (unsigned char *)opt;

  /* and add new node to receive queue */
  coap_insert_node( &ctx->recvqueue, node, order_transaction_id );

#ifndef NDEBUG
  if ( inet_ntop(src.sin6_family, &src.sin6_addr, addr, INET6_ADDRSTRLEN) == 0 ) {
    //perror("coap_read: inet_ntop");
  } else {
    printf( "** received from [%s]:%d:\n  ",addr,ntohs(src.sin6_port));
  }
  coap_show_pdu( node->pdu );
#endif

  return 0;
}

//CLIENT:
int
order_opts(void *a, void *b) {
  if (!a || !b)
    return a < b ? -1 : 1;

  if (COAP_OPTION_KEY(*(coap_option *)a) < COAP_OPTION_KEY(*(coap_option *)b))
    return -1;

  return COAP_OPTION_KEY(*(coap_option *)a) == COAP_OPTION_KEY(*(coap_option *)b);
}

//CLIENT:
coap_list_t *
new_option_node(unsigned short key, unsigned int length, char *data) {
  coap_option *option;
  coap_list_t *node;

  option = coap_malloc(sizeof(coap_option) + length);
  if ( !option )
    goto error;

  COAP_OPTION_KEY(*option) = key;
  COAP_OPTION_LENGTH(*option) = length;
  memcpy(COAP_OPTION_DATA(*option), data, length);

  /* we can pass NULL here as delete function since option is released automatically  */
  node = coap_new_listnode(option, NULL);

  if ( node )
    return node;

 error:
  //perror("new_option_node: malloc");
  coap_free( option );
  return NULL;
}
