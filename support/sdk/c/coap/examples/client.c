/* coap-client -- simple CoAP client
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
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "coap.h"

static coap_list_t *optlist = NULL;
/* Request URI.
 * TODO: associate the resources with transaction id and make it expireable */
static coap_uri_t uri;

/* reading is done when this flag is set */
static int ready = 0;
static FILE *file = NULL;	/* output file name */

static str payload = { 0, NULL }; /* optional payload to send */

typedef unsigned char method_t;
method_t method = 1;		/* the method we are using in our requests */

extern unsigned int
print_readable( const unsigned char *data, unsigned int len,
		unsigned char *result, unsigned int buflen );

int
append_to_file(const char *filename, const unsigned char *data, size_t len) {
  size_t written;

  if ( !file && !(file = fopen(filename, "w")) ) {
    perror("append_to_file: fopen");
    return -1;
  }

  do {
    written = fwrite(data, 1, len, file);
    len -= written;
    data += written;
  } while ( written && len );

  return 0;
}

coap_pdu_t *
new_ack( coap_context_t  *ctx, coap_queue_t *node ) {
  coap_pdu_t *pdu = coap_new_pdu();

  if (pdu) {
    pdu->hdr->type = COAP_MESSAGE_ACK;
    pdu->hdr->code = 0;
    pdu->hdr->id = node->pdu->hdr->id;
  }

  return pdu;
}

coap_pdu_t *
new_response( coap_context_t  *ctx, coap_queue_t *node, unsigned int code ) {
  coap_pdu_t *pdu = new_ack(ctx, node);

  if (pdu)
    pdu->hdr->code = code;

  return pdu;
}

coap_pdu_t *
coap_new_request( method_t m, coap_list_t *options ) {
  coap_pdu_t *pdu;
  coap_list_t *opt;

  if ( ! ( pdu = coap_new_pdu() ) )
    return NULL;

  pdu->hdr->type = COAP_MESSAGE_CON;
  pdu->hdr->id = rand();	/* use a random transaction id */
  pdu->hdr->code = m;

  for (opt = options; opt; opt = opt->next) {
    coap_add_option( pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
		     COAP_OPTION_LENGTH(*(coap_option *)opt->data),
		     COAP_OPTION_DATA(*(coap_option *)opt->data) );
  }

  if (payload.length) {
    /* TODO: must handle block */
    coap_add_data(pdu, payload.length, payload.s);
  }

  return pdu;
}

void
send_request( coap_context_t  *ctx, coap_pdu_t  *pdu, const char *server, unsigned short port ) {
  struct addrinfo *res, *ainfo;
  struct addrinfo hints;
  int error;
  struct sockaddr_in6 dst;
  static unsigned char buf[COAP_MAX_PDU_SIZE];
  memset ((char *)&hints, 0, sizeof(hints));
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_family = AF_INET6;

  error = getaddrinfo(server, "", &hints, &res);

  if (error != 0) {
    perror("getaddrinfo");
    exit(1);
  }

  for (ainfo = res; ainfo != NULL; ainfo = ainfo->ai_next) {

    if ( ainfo->ai_family == AF_INET6 ) {

      memset(&dst, 0, sizeof dst );
      dst.sin6_family = AF_INET6;
      dst.sin6_port = htons( port );
      memcpy( &dst.sin6_addr, &((struct sockaddr_in6 *)ainfo->ai_addr)->sin6_addr, sizeof(dst.sin6_addr) );

      print_readable( (unsigned char *)pdu->hdr, pdu->length, buf, COAP_MAX_PDU_SIZE);
      printf("%s\n",buf);
      coap_send_confirmed( ctx, &dst, pdu );
      goto leave;
    }
  }

 leave:
  freeaddrinfo(res);
}

#define COAP_OPT_BLOCK_LAST(opt) ( COAP_OPT_VALUE(*block) + (COAP_OPT_LENGTH(*block) - 1) )
#define COAP_OPT_BLOCK_MORE(opt) ( *COAP_OPT_LAST(*block) & 0x08 )
#define COAP_OPT_BLOCK_SIZE(opt) ( *COAP_OPT_LAST(*block) & 0x07 )

unsigned int
_read_blk_nr(coap_opt_t *opt) {
  unsigned int i, nr=0;
  for ( i = COAP_OPT_LENGTH(*opt); i; --i) {
    nr = (nr << 8) + COAP_OPT_VALUE(*opt)[i-1];
  }
  return nr >> 4;
}
#define COAP_OPT_BLOCK_NR(opt)   _read_blk_nr(&opt)

#ifdef SHOWREALVALUES
typedef struct val
{
  uint8_t id_t:4;
  uint8_t length_t:4;
  uint16_t temp;
  uint8_t id_h:4;
  uint8_t length_h:4;
  uint16_t hum;
  uint8_t id_v:4;
  uint8_t length_v:4;
  uint16_t volt;
}__attribute__((__packed__)) val_all ;

val_all
char_to_val_all(unsigned char *data) {
  val_all result;
  memcpy(&result, data, sizeof(val_all));
  return result;
}

uint16_t
char_to_uint16(unsigned char *data) {
  uint16_t result;
  memcpy(&result, data, sizeof(uint16_t));
  return result;
}
#endif

void
message_handler( coap_context_t  *ctx, coap_queue_t *node, void *data) {
  coap_pdu_t *pdu = NULL;
  coap_opt_t *block, *ct, *sub;
  unsigned int blocknr;
  unsigned char buf[4];
  coap_list_t *option;
  unsigned int len;
  unsigned char *databuf;

#ifndef NDEBUG
  printf("** process pdu: ");
  coap_show_pdu( node->pdu );
#endif

  if ( node->pdu->hdr->version != COAP_DEFAULT_VERSION ) {
    debug("dropped packet with unknown version %u\n", node->pdu->hdr->version);
    return;
  }

  if ( node->pdu->hdr->code < COAP_RESPONSE_100 && node->pdu->hdr->type == COAP_MESSAGE_CON ) {
    /* send 500 response */
    pdu = new_response( ctx, node, COAP_RESPONSE_500 );
    goto finish;
  }

  switch (node->pdu->hdr->code) {
  case COAP_RESPONSE_200:
    /* got some data, check if block option is set */
    block = coap_check_option( node->pdu, COAP_OPTION_BLOCK );
    if ( !block ) {
      /* There is no block option set, just read the data and we are done. */
      if ( coap_get_data( node->pdu, &len, &databuf ) ) {
	/*path = coap_check_option( node->pdu, COAP_OPTION_URI_PATH );*/
	append_to_file( "coap.out", databuf, len );
      }
    } else {
      blocknr = coap_decode_var_bytes( COAP_OPT_VALUE(*block), COAP_OPT_LENGTH(*block) );

      /* TODO: check if we are looking at the correct block number */
      if ( coap_get_data( node->pdu, &len, &databuf ) ) {
	/*path = coap_check_option( node->pdu, COAP_OPTION_URI_PATH );*/
	append_to_file( "coap.out", databuf, len );
      }

      if ( (blocknr & 0x08) ) {
	/* more bit is set */
	printf("found the M bit, block size is %u, block nr. %u\n",
	       blocknr & 0x07,
	       (blocknr & 0xf0) << blocknr & 0x07);

	/* need to acknowledge if message was asyncronous */
	if ( node->pdu->hdr->type == COAP_MESSAGE_CON ) {
	  pdu = new_ack( ctx, node );

	  if ( pdu && coap_send( ctx, &node->remote, pdu ) == COAP_INVALID_TID ) {
	    debug("message_handler: error sending reponse");
	    coap_delete_pdu(pdu);
	    return;
	  }
	}

	/* create pdu with request for next block */
	pdu = coap_new_request( method, NULL ); /* first, create bare PDU w/o any option  */
	if ( pdu ) {
	  pdu->hdr->id = node->pdu->hdr->id; /* copy transaction id from response */

	  /* get content type from response */
	  ct = coap_check_option( node->pdu, COAP_OPTION_CONTENT_TYPE );
	  if ( ct ) {
	    coap_add_option( pdu, COAP_OPTION_CONTENT_TYPE,
			     COAP_OPT_LENGTH(*ct),COAP_OPT_VALUE(*ct) );
	  }

	  /* add URI components from optlist */
	  for (option = optlist; option; option = option->next ) {
	    switch (COAP_OPTION_KEY(*(coap_option *)option->data)) {
	    case COAP_OPTION_URI_AUTHORITY :
	    case COAP_OPTION_URI_PATH :
	    case COAP_OPTION_URI_QUERY :
	      coap_add_option ( pdu, COAP_OPTION_KEY(*(coap_option *)option->data),
				COAP_OPTION_LENGTH(*(coap_option *)option->data),
				COAP_OPTION_DATA(*(coap_option *)option->data) );
	      break;
	    default:
	      ;			/* skip other options */
	    }
	  }

	  /* finally add updated block option from response */
	  coap_add_option ( pdu, COAP_OPTION_BLOCK,
			    coap_encode_var_bytes(buf, blocknr + ( 1 << 4) ), buf);

	  if ( coap_send_confirmed( ctx, &node->remote, pdu ) == COAP_INVALID_TID ) {
	    debug("message_handler: error sending reponse");
	    coap_delete_pdu(pdu);
	  }
	  return;
	}
      }
    }

#ifdef SHOWREALVALUES

    if (strcmp((const char *)uri.path.s, "st") == 0 ) {
      printf("\n** Temperatur: %4.2f K\n\n", ((float)char_to_uint16(node->pdu->data))/100);
    } else if (strcmp((const char *)uri.path.s, "sh") == 0) {
      printf("\n** Humidity: %4.2f %% \n\n",  ((float)char_to_uint16(node->pdu->data))/100);
    } else if (strcmp((const char *)uri.path.s, "sv") == 0) {
      printf("** Voltage: %4.2f V\n\n",  ((float)char_to_uint16(node->pdu->data))/100);
    } else if (strcmp((const char *)uri.path.s, "ck") == 0) {
      if (len != 0) {
	printf("** AES Key received \n");
      } else {
	printf("** AES Key set\n");
      }
    } else if (strcmp((const char *)uri.path.s, "tsr") == 0) {
      printf("** tsr\n");
    } else if (strcmp((const char *)uri.path.s, "par") == 0) {
      printf("** par\n");
    } else if (strcmp((const char *)uri.path.s, "l") == 0) {
      if (len != 0) {
	printf("\n** led 0 (red)   %s\n** led 1 (green) %s\n** led 2 (blue)  %s\n\n",
	       ( (char_to_uint16(node->pdu->data)    %2) == 0) ? "OFF": "ON",
	       (((char_to_uint16(node->pdu->data)>>1)%2) == 0) ? "OFF": "ON",
	       (((char_to_uint16(node->pdu->data)>>2)%2) == 0) ? "OFF": "ON");
      } else {
	printf("** LEDs set\n");
      }
    } else if (strcmp((const char *)uri.path.s, "rt") == 0) {
      printf("** Route:\ndestination\t\tgateway\t\tiface\n %s\n", node->pdu->data);
    } else if (strcmp((const char *)uri.path.s, "r") == 0) {
      val_all val = char_to_val_all(node->pdu->data);
      printf("\n** All values: \n");
      if (val.temp != (0xFFFF | 0xFFFE))
	printf("** Temperature: %4.2f K\n", ((float) val.temp)/100);
      else
	printf("** Temperature:     NaN\n\n");
      if (val.hum != (0xFFFF | 0xFFFE))
	printf("** Humidity:    %4.2f %%\n",  ((float) val.hum)/100);
      else
	printf("** Humidity:     NaN\n\n");
      if (val.volt != (0xFFFF | 0xFFFE))
	printf("** Voltage:     %4.2f V\n\n",  ((float) val.volt)/100);
      else
	printf("** Voltage:     NaN\n\n");
    } else if (strcmp((const char *)uri.path.s, "lipsum") == 0) {
    } else if (strcmp((const char *)uri.path.s, "time") == 0) {
    } else if (strcmp((const char *)uri.path.s, COAP_DEFAULT_URI_WELLKNOWN) == 0) {
      printf("** .well-known/core:\n");
    } else {
      printf("** unknown URI\n");
    }
#endif

    break;
  case COAP_RESPONSE_X_240:
    printf("\n** Token required\n\n");
    break;
  case 0:
    printf("** PreAck received\n");
    break;
  default:
    ;
  }

  /* acknowledge if requested */
  if ( !pdu && node->pdu->hdr->type == COAP_MESSAGE_CON ) {
    pdu = new_ack( ctx, node );
  }

 finish:
  if ( pdu && coap_send( ctx, &node->remote, pdu ) == COAP_INVALID_TID ) {
    debug("message_handler: error sending reponse");
    coap_delete_pdu(pdu);
  }

  /* our job is done, we can exit at any time */
  sub = coap_check_option( node->pdu, COAP_OPTION_SUBSCRIPTION );
  if ( sub ) {
    debug("message_handler: Subscription-Lifetime is %d\n",
	  COAP_PSEUDOFP_DECODE_8_4(*COAP_OPT_VALUE(*sub)));
  }
  ready = !sub || COAP_PSEUDOFP_DECODE_8_4(*COAP_OPT_VALUE(*sub)) == 0;
}

void
usage( const char *program, const char *version) {
  const char *p;

  p = strrchr( program, '/' );
  if ( p )
    program = ++p;

  fprintf( stderr, "%s v%s -- a small CoAP implementation\n"
	   "(c) 2010 Olaf Bergmann <bergmann@tzi.org>\n\n"
	   "usage: %s [-b num] [-g group] [-m method] [-p port] [-s num] [-t type...] [-T string] URI\n\n"
	   "\tURI can be an absolute or relative coap URI,\n"
	   "\t-b size\t\tblock size to be used in GET/PUT/POST requests\n"
	   "\t       \t\t(value must be a multiple of 16 not larger than 2048)\n"
	   "\t-f file\t\tfile to send with PUT/POST (use '-' for STDIN)\n"
	   "\t-g group\tjoin the given multicast group\n"
	   "\t-m method\trequest method (get|put|post|delete)\n"
	   "\t-p port\t\tlisten on specified port\n"
	   "\t-s duration\tsubscribe for given duration [s]\n"
	   "\t-A types\taccepted content for GET (comma-separated list)\n"
	   "\t-t type\t\tcontent type for given resource for PUT/POST\n"
	   "\t-T token\tinclude specified token\n",
	   program, version, program );
}

int
join( coap_context_t *ctx, char *group_name ){
  struct ipv6_mreq mreq;
  struct addrinfo   *reslocal = NULL, *resmulti = NULL, hints, *ainfo;
  int result = -1;

  /* we have to resolve the link-local interface to get the interface id */
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET6;
  hints.ai_socktype = SOCK_DGRAM;

  result = getaddrinfo("::", NULL, &hints, &reslocal);
  if ( result < 0 ) {
    perror("join: cannot resolve link-local interface");
    goto finish;
  }

  /* get the first suitable interface identifier */
  for (ainfo = reslocal; ainfo != NULL; ainfo = ainfo->ai_next) {
    if ( ainfo->ai_family == AF_INET6 ) {
      mreq.ipv6mr_interface =
	((struct sockaddr_in6 *)ainfo->ai_addr)->sin6_scope_id;
      break;
    }
  }

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET6;
  hints.ai_socktype = SOCK_DGRAM;

  /* resolve the multicast group address */
  result = getaddrinfo(group_name, NULL, &hints, &resmulti);

  if ( result < 0 ) {
    perror("join: cannot resolve multicast address");
    goto finish;
  }

  for (ainfo = resmulti; ainfo != NULL; ainfo = ainfo->ai_next) {
    if ( ainfo->ai_family == AF_INET6 ) {
      mreq.ipv6mr_multiaddr =
	((struct sockaddr_in6 *)ainfo->ai_addr)->sin6_addr;
      break;
    }
  }

  result = setsockopt( ctx->sockfd, IPPROTO_IPV6, IPV6_JOIN_GROUP,
		       (char *)&mreq, sizeof(mreq) );
  if ( result < 0 )
    perror("join: setsockopt");

 finish:
  freeaddrinfo(resmulti);
  freeaddrinfo(reslocal);

  return result;
}

int
order_opts(void *a, void *b) {
  if (!a || !b)
    return a < b ? -1 : 1;

  if (COAP_OPTION_KEY(*(coap_option *)a) < COAP_OPTION_KEY(*(coap_option *)b))
    return -1;

  return COAP_OPTION_KEY(*(coap_option *)a) == COAP_OPTION_KEY(*(coap_option *)b);
}


coap_list_t *
new_option_node(unsigned short key, unsigned int length, unsigned char *data) {
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
  perror("new_option_node: malloc");
  coap_free( option );
  return NULL;
}

void
cmdline_content_type(char *arg, unsigned short key) {
  static char *content_types[] =
    { "plain", "xml", "csv", "html", "","","","","","","","","","","","","","","","","",
      "gif", "jpeg", "png", "tiff", "audio", "video", "","","","","","","","","","","","","",
      "link", "axml", "binary", "rdf", "soap", "atom", "xmpp", "exi",
      "bxml", "infoset", "json", 0};
  coap_list_t *node;
  unsigned char i, value[10];
  int valcnt = 0;
  char *p, *q = arg;

  while (q && *q) {
    p = strchr(q, ',');

    for (i=0; content_types[i] &&
	   strncmp(q,content_types[i], p ? p-q : strlen(q)) != 0 ;
	 ++i)
      ;

    if (content_types[i]) {
      value[valcnt] = i;
      valcnt++;
    } else {
      fprintf(stderr, "W: unknown content-type '%s'\n",arg);
    }

    if (!p || key == COAP_OPTION_CONTENT_TYPE)
      break;

    q = p+1;
  }

  if (valcnt) {
    node = new_option_node(key, valcnt, value);
    if (node)
      coap_insert( &optlist, node, order_opts );
  }
}

void
cmdline_uri(char *arg) {
  coap_split_uri((unsigned char *)arg, &uri );

#if 0  /* need authority only for proxy requests */
  if (uri.na.length)
    coap_insert( &optlist, new_option_node(COAP_OPTION_URI_AUTHORITY,
					   uri.na.length, uri.na.s),
		 order_opts);
#endif
  if (uri.path.length)
    coap_insert( &optlist, new_option_node(COAP_OPTION_URI_PATH,
					   uri.path.length, uri.path.s),
		 order_opts);

  if (uri.query.length)
    coap_insert( &optlist, new_option_node(COAP_OPTION_URI_QUERY,
					   uri.query.length, uri.query.s),
		 order_opts);
}

void
cmdline_blocksize(char *arg) {
  static unsigned char buf[4];	/* hack: temporarily take encoded bytes */
  unsigned int blocksize = atoi(arg);

  if ( COAP_MAX_PDU_SIZE < blocksize + sizeof(coap_hdr_t) ) {
    fprintf(stderr, "W: skipped invalid blocksize\n");
    return;
  }

  /* use only last three bits and clear M-bit */
  blocksize = (coap_fls(blocksize >> 4) - 1) & 0x07;
  coap_insert( &optlist, new_option_node(COAP_OPTION_BLOCK,
					 coap_encode_var_bytes(buf, blocksize), buf),
	       order_opts);
}

void
cmdline_subscribe(char *arg) {
  unsigned int ls, s;
  unsigned char duration = COAP_PSEUDOFP_ENCODE_8_4_UP(atoi(arg), ls, s);

  coap_insert( &optlist, new_option_node(COAP_OPTION_SUBSCRIPTION,
					 1, &duration), order_opts );
}

void
cmdline_token(char *arg) {
  coap_insert( &optlist, new_option_node(COAP_OPTION_TOKEN,
					 strlen(arg),
					 (unsigned char *)arg), order_opts);
}

int
cmdline_input_from_file(char *filename, str *buf) {
  FILE *inputfile = NULL;
  ssize_t len;
  int result = 1;
  struct stat statbuf;

  if (!filename || !buf)
    return 0;

  if (filename[0] == '-' && !filename[1]) { /* read from stdin */
    buf->length = 20000;
    buf->s = (unsigned char *)coap_malloc(buf->length);
    if (!buf->s)
      return 0;

    inputfile = stdin;
  } else {
    /* read from specified input file */
    if (stat(filename, &statbuf) < 0) {
      perror("cmdline_input_from_file: stat");
      return 0;
    }

    buf->length = statbuf.st_size;
    buf->s = (unsigned char *)coap_malloc(buf->length);
    if (!buf->s)
      return 0;

    inputfile = fopen(filename, "r");
    if ( !inputfile ) {
      perror("cmdline_input_from_file: fopen");
      coap_free(buf->s);
      return 0;
    }
  }

  len = fread(buf->s, 1, buf->length, inputfile);

  if (len < buf->length) {
    if (ferror(inputfile) != 0) {
      perror("cmdline_input_from_file: fread");
      coap_free(buf->s);
      buf->length = 0;
      buf->s = NULL;
      result = 0;
    } else {
      buf->length = len;
    }
  }

  if (inputfile != stdin)
    fclose(inputfile);

  return result;
}

method_t
cmdline_method(char *arg) {
  static char *methods[] =
    { 0, "get", "post", "put", "delete", 0};
  unsigned char i;

  for (i=1; methods[i] && strcasecmp(arg,methods[i]) != 0 ; ++i)
    ;

  return i;	     /* note that we do not prevent illegal methods */
}

int
main(int argc, char **argv) {
  coap_context_t  *ctx;
  fd_set readfds;
  struct timeval tv, *timeout;
  int result;
  time_t now;
  coap_queue_t *nextpdu;
  coap_pdu_t  *pdu;
  static unsigned char *p;
  static str server;
  unsigned short localport = COAP_DEFAULT_PORT, port = COAP_DEFAULT_PORT;
  int opt;
  char *group = NULL;

  while ((opt = getopt(argc, argv, "b:f:g:m:p:s:t:A:T:")) != -1) {
    switch (opt) {
    case 'b' :
      cmdline_blocksize(optarg);
      break;
    case 'f' :
      cmdline_input_from_file(optarg,&payload);
      break;
    case 'g' :
      group = optarg;
      break;
    case 'p' :
      localport = atoi(optarg);
      break;
    case 'm' :
      method = cmdline_method(optarg);
      break;
    case 's' :
      cmdline_subscribe(optarg);
      break;
    case 'A' :
      cmdline_content_type(optarg,COAP_OPTION_ACCEPT);
      break;
    case 't' :
      cmdline_content_type(optarg,COAP_OPTION_CONTENT_TYPE);
      break;
    case 'T' :
      cmdline_token(optarg);
      break;
    default:
      usage( argv[0], PACKAGE_VERSION );
      exit( 1 );
    }
  }

  ctx = coap_new_context( localport );
  if ( !ctx )
    return -1;

  coap_register_message_handler( ctx, message_handler );

  if ( optind < argc )
    cmdline_uri( argv[optind] );
  else {
    usage( argv[0], PACKAGE_VERSION );
    exit( 1 );
  }

  if ( group )
    join( ctx, group );

  if (! (pdu = coap_new_request( method, optlist ) ) )
    return -1;

  /* split server address and port */
  /* FIXME: get rid of the global URI object somehow */
  server = uri.na;

  if (server.length) {
    if (*server.s == '[') {	/* IPv6 address reference */
      p = ++server.s;
      --server.length;

      while ( p - server.s < server.length && *p != ']' )
	++p;

      if (*p == ']')
	*p++ = '\0';		/* port starts here */
    } else {			/* IPv4 address or hostname */
      p = server.s;
      while ( p - server.s < server.length && *p != ':' )
	++p;
    }

    if (*p == ':') {		/* port starts here */
      *p++ = '\0';
      port = 0;

      /* set port */
      while( p - server.s < server.length && isdigit(*p) ) {
	port = port * 10 + ( *p - '0' );
	++p;
      }
    }
  }

  /* send request */
  send_request( ctx, pdu, server.length ? (char *)server.s : "::1", port );

  while ( !(ready && coap_can_exit(ctx)) ) {
    FD_ZERO(&readfds);
    FD_SET( ctx->sockfd, &readfds );

    nextpdu = coap_peek_next( ctx );

    time(&now);
    while ( nextpdu && nextpdu->t <= now ) {
      coap_retransmit( ctx, coap_pop_next( ctx ) );
      nextpdu = coap_peek_next( ctx );
    }

    if ( nextpdu ) {	        /* set timeout if there is a pdu to send */
      tv.tv_usec = 0;
      tv.tv_sec = nextpdu->t - now;
      timeout = &tv;
    } else
      timeout = NULL;		/* no timeout otherwise */

    result = select( ctx->sockfd + 1, &readfds, 0, 0, timeout );

    if ( result < 0 ) {		/* error */
      perror("select");
    } else if ( result > 0 ) {	/* read from socket */
      if ( FD_ISSET( ctx->sockfd, &readfds ) ) {
	coap_read( ctx );	/* read received data */
	coap_dispatch( ctx );	/* and dispatch PDUs from receivequeue */

	// koo second read is done to process the asyn response. TODO this has to be done properly by checking the type of message
	//coap_read( ctx );	/* read received data */
	//coap_dispatch( ctx );	/* and dispatch PDUs from receivequeue */
	// koo
      }
    }
  }

  if ( file ) {
    fflush( file );
    fclose( file );
  }
  coap_free_context( ctx );

  return 0;
}
