/* coap-client -- simple CoAP client
 *
 * Copyright (C) 2010--2012 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#include "config.h"

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
static str proxy = { 0, NULL };

/* reading is done when this flag is set */
static int ready = 0;

static str output_file = { 0, NULL }; /* output file name */
static FILE *file = NULL;	/* output file stream */

static str payload = { 0, NULL }; /* optional payload to send */

unsigned char msgtype = COAP_MESSAGE_CON; /* usually, requests are sent confirmable */

typedef unsigned char method_t;
method_t method = 1;		/* the method we are using in our requests */

unsigned int blocknr = 0;	/* current block num*/
unsigned char blockszx = 6;	/* current block szx */

unsigned int wait_seconds = 90;	/* default timeout in seconds */

#define min(a,b) ((a) < (b) ? (a) : (b))

extern unsigned int
print_readable( const unsigned char *data, unsigned int len,
		unsigned char *result, unsigned int buflen );

int
append_to_output(const unsigned char *data, size_t len) {
  size_t written;

  if (!file) {
    if (!output_file.s || (output_file.length && output_file.s[0] == '-')) 
      file = stdout;
    else {
      if (!(file = fopen((char *)output_file.s, "w"))) {
	perror("fopen");
	return -1;
      }
    }
  }

  do {
    written = fwrite(data, 1, len, file);
    len -= written;
    data += written;
  } while ( written && len );

  return 0;
}

void
close_output() {
  if (file) {

    /* add a newline before closing in case were writing to stdout */
    if (!output_file.s || (output_file.length && output_file.s[0] == '-')) 
      fwrite("\n", 1, 1, file);

    fflush(file);
    fclose(file);
  }
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
coap_new_request(coap_context_t *ctx, method_t m, coap_list_t *options ) {
  coap_pdu_t *pdu;
  coap_list_t *opt;
  int res;
#define BUFSIZE 40
  unsigned char _buf[BUFSIZE];
  unsigned char *buf = _buf;
  size_t buflen;

  if ( ! ( pdu = coap_new_pdu() ) )
    return NULL;

  pdu->hdr->type = msgtype;
  pdu->hdr->id = coap_new_message_id(ctx);
  pdu->hdr->code = m;

  for (opt = options; opt; opt = opt->next) {

    /* path names shall be split into segments */
    if (COAP_OPTION_KEY(*(coap_option *)opt->data) == COAP_OPTION_URI_PATH) {
      buflen = BUFSIZE;
      res = coap_split_path(COAP_OPTION_DATA(*(coap_option *)opt->data),
			    COAP_OPTION_LENGTH(*(coap_option *)opt->data),
			    buf, &buflen);
      
      while (res--) {
	coap_add_option(pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
			COAP_OPT_LENGTH(buf),
			COAP_OPT_VALUE(buf));

	buf += COAP_OPT_SIZE(buf);      
      }
    } else if (COAP_OPTION_KEY(*(coap_option *)opt->data) == 
	       COAP_OPTION_URI_QUERY) {
      buflen = BUFSIZE;
      buf = _buf;
      res = coap_split_query(COAP_OPTION_DATA(*(coap_option *)opt->data),
			     COAP_OPTION_LENGTH(*(coap_option *)opt->data),
			     buf, &buflen);
      
      while (res--) {
	coap_add_option(pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
			COAP_OPT_LENGTH(buf),
			COAP_OPT_VALUE(buf));

	buf += COAP_OPT_SIZE(buf);      
      }
    } else { /* any other option is copied literally */
      coap_add_option(pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
		      COAP_OPTION_LENGTH(*(coap_option *)opt->data),
		      COAP_OPTION_DATA(*(coap_option *)opt->data));
    }
  }

  if (payload.length) {
    /* TODO: must handle block */

    coap_add_data(pdu, payload.length, payload.s);
  }

  return pdu;
}

int 
resolve_address(const str *server, struct sockaddr *dst) {
  
  struct addrinfo *res, *ainfo;
  struct addrinfo hints;
  static char addrstr[256];
  int error;

  memset(addrstr, 0, sizeof(addrstr));
  if (server->length)
    memcpy(addrstr, server->s, server->length);
  else
    memcpy(addrstr, "localhost", 9);

  memset ((char *)&hints, 0, sizeof(hints));
  hints.ai_socktype = SOCK_DGRAM;
  hints.ai_family = AF_UNSPEC;

  error = getaddrinfo(addrstr, "", &hints, &res);

  if (error != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(error));
    return error;
  }

  for (ainfo = res; ainfo != NULL; ainfo = ainfo->ai_next) {

    switch (ainfo->ai_family) {
    case AF_INET6:
    case AF_INET:

      memcpy(dst, ainfo->ai_addr, ainfo->ai_addrlen);
      return ainfo->ai_addrlen;
    default:
      ;
    }
  }

  freeaddrinfo(res);
  return -1;
}

static inline coap_opt_t *
get_block(coap_pdu_t *pdu, coap_opt_iterator_t *opt_iter) {
  coap_opt_filter_t f;
  
  assert(pdu);

  memset(f, 0, sizeof(coap_opt_filter_t));
  coap_option_setb(f, COAP_OPTION_BLOCK1);
  coap_option_setb(f, COAP_OPTION_BLOCK2);

  coap_option_iterator_init(pdu, opt_iter, f);
  return coap_option_next(opt_iter);
}

void
message_handler(struct coap_context_t  *ctx, 
		const coap_address_t *remote, 
		coap_pdu_t *sent,
		coap_pdu_t *received,
		const coap_tid_t id) {

  coap_pdu_t *pdu = NULL;
  coap_opt_t *block, *sub;
  coap_opt_iterator_t opt_iter;
  unsigned char buf[4];
  coap_list_t *option;
  size_t len;
  unsigned char *databuf;
  coap_tid_t tid;

#ifndef NDEBUG
  if (LOG_DEBUG <= coap_get_log_level()) {
    debug("** process incoming %d.%02d response:\n",
	  (received->hdr->code >> 5), received->hdr->code & 0x1F);
    coap_show_pdu(received);
  }
#endif

  switch (received->hdr->type) {
  case COAP_MESSAGE_CON:
    /* acknowledge received response if confirmable (TODO: check Token) */
    coap_send_ack(ctx, remote, received);
    break;
  case COAP_MESSAGE_RST:
    info("got RST\n");
    return;
  default:
    ;
  }

  /* output the received data, if any */
  if (received->hdr->code == COAP_RESPONSE_CODE(205)) { 
    
    /* Got some data, check if block option is set. Behavior is undefined if
     * both, Block1 and Block2 are present. */
    block = get_block(received, &opt_iter);
    if ( !block ) {
      /* There is no block option set, just read the data and we are done. */
      if (coap_get_data(received, &len, &databuf))
	append_to_output(databuf, len);
    } else {
      unsigned short blktype = opt_iter.type;

      /* TODO: check if we are looking at the correct block number */
      if (coap_get_data(received, &len, &databuf))
	append_to_output(databuf, len);

      if (COAP_OPT_BLOCK_MORE(block)) {
	/* more bit is set */
	debug("found the M bit, block size is %u, block nr. %u\n",
	      COAP_OPT_BLOCK_SZX(block), COAP_OPT_BLOCK_NUM(block));

	/* create pdu with request for next block */
	pdu = coap_new_request(ctx, method, NULL); /* first, create bare PDU w/o any option  */
	if ( pdu ) {
	  /* add URI components from optlist */
	  for (option = optlist; option; option = option->next ) {
	    switch (COAP_OPTION_KEY(*(coap_option *)option->data)) {
	    case COAP_OPTION_URI_HOST :
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

	  /* finally add updated block option from response, clear M bit */
	  /* blocknr = (blocknr & 0xfffffff7) + 0x10; */
	  debug("query block %d\n", (COAP_OPT_BLOCK_NUM(block) + 1));
	  coap_add_option(pdu, blktype, coap_encode_var_bytes(buf, 
	      ((COAP_OPT_BLOCK_NUM(block) + 1) << 4) | 
              COAP_OPT_BLOCK_SZX(block)), buf);

	  if (received->hdr->type == COAP_MESSAGE_CON)
	    tid = coap_send_confirmed(ctx, remote, pdu);
	  else 
	    tid = coap_send(ctx, remote, pdu);

	  if (tid == COAP_INVALID_TID) {
	    debug("message_handler: error sending new request");
	    coap_delete_pdu(pdu);
	  }
	  return;
	}
      }
    }
  } else {			/* no 2.05 */

    /* check if an error was signaled and output payload if so */
    if (COAP_RESPONSE_CLASS(received->hdr->code) >= 4) {
      fprintf(stderr, "%d.%02d", 
	      (received->hdr->code >> 5), received->hdr->code & 0x1F);
      if (coap_get_data(received, &len, &databuf)) {
      fprintf(stderr, " ");
	while(len--)
	  fprintf(stderr, "%c", *databuf++);
      }
      fprintf(stderr, "\n");
    }
    
  }

  /* finally send new request, if needed */
  if (pdu && coap_send(ctx, remote, pdu) == COAP_INVALID_TID) {
    debug("message_handler: error sending reponse");
    coap_delete_pdu(pdu);
  }

  /* our job is done, we can exit at any time */
  sub = coap_check_option(received, COAP_OPTION_SUBSCRIPTION, &opt_iter);
#ifndef NDEBUG
  if ( sub ) {
    debug("message_handler: Subscription-Lifetime is %d\n",
	  COAP_PSEUDOFP_DECODE_8_4(*COAP_OPT_VALUE(sub)));
  }
#endif
  ready = !sub || COAP_PSEUDOFP_DECODE_8_4(*COAP_OPT_VALUE(sub)) == 0;
}

void
usage( const char *program, const char *version) {
  const char *p;

  p = strrchr( program, '/' );
  if ( p )
    program = ++p;

  fprintf( stderr, "%s v%s -- a small CoAP implementation\n"
	   "(c) 2010-2012 Olaf Bergmann <bergmann@tzi.org>\n\n"
	   "usage: %s [-A type...] [-b [num,]size] [-B seconds] [-e text]\n"
	   "\t\t[-g group] [-m method] [-N] [-o file] [-P addr[:port]] [-p port]\n"
	   "\t\t[-s duration] [-t type...] [-O num,text]\n"
	   "\t\t[-T string] [-v num] URI\n\n"
	   "\tURI can be an absolute or relative coap URI,\n"
	   "\t-A type...\taccepted media types as comma-separated list of\n"
	   "\t\t\tsymbolic or numeric values\n"
	   "\t-b size\t\tblock size to be used in GET/PUT/POST requests\n"
	   "\t       \t\t(value must be a multiple of 16 not larger than 1024)\n"
	   "\t-B seconds\tbreak operation after waiting given seconds\n"
	   "\t\t\t(default is %d)\n"
	   "\t-e text\t\tinclude text as payload (use percent-encoding for\n"
	   "\t\t\tnon-ASCII characters)\n"
	   "\t-f file\t\tfile to send with PUT/POST (use '-' for STDIN)\n"
	   "\t-g group\tjoin the given multicast group\n"
	   "\t-m method\trequest method (get|put|post|delete), default is 'get'\n"
	   "\t-N\t\tsend NON-confirmable message\n"
	   "\t-o file\t\toutput received data to this file (use '-' for STDOUT)\n"
	   "\t-p port\t\tlisten on specified port\n"
	   "\t-s duration\tsubscribe for given duration [s]\n"
	   "\t-v num\t\tverbosity level (default: 3)\n"
	   "\t-A types\taccepted content for GET (comma-separated list)\n"
	   "\t-t type\t\tcontent type for given resource for PUT/POST\n"
	   "\t-O num,text\tadd option num with contents text to request\n"
	   "\t-P addr[:port]\tuse proxy (automatically adds Proxy-Uri option to\n"
	   "\t\t\trequest)\n"
	   "\t-T token\tinclude specified token\n",
	   program, version, program, wait_seconds);
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
    fprintf(stderr, "join: cannot resolve link-local interface: %s\n", 
	    gai_strerror(result));
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
    fprintf(stderr, "join: cannot resolve multicast address: %s\n", 
	    gai_strerror(result));
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

typedef struct { 
  unsigned char code;
  char *media_type;
} content_type_t;

void
cmdline_content_type(char *arg, unsigned short key) {
  static content_type_t content_types[] = {
    {  0, "plain" },
    {  0, "text/plain" },
    { 40, "link" },
    { 40, "link-format" },
    { 40, "application/link-format" },
    { 41, "xml" },
    { 42, "binary" },
    { 42, "octet-stream" },
    { 42, "application/octet-stream" },
    { 47, "exi" },
    { 47, "application/exi" },
    { 50, "json" },
    { 50, "application/json" },
    { 255, NULL }
  };
  coap_list_t *node;
  unsigned char i, value[10];
  int valcnt = 0;
  unsigned char buf[2];
  char *p, *q = arg;

  while (q && *q) {
    p = strchr(q, ',');

    if (isdigit(*q)) {
      if (p)
	*p = '\0';
      value[valcnt++] = atoi(q);
    } else {
      for (i=0; content_types[i].media_type &&
	     strncmp(q,content_types[i].media_type, p ? p-q : strlen(q)) != 0 ;
	   ++i)
	;
      
      if (content_types[i].media_type) {
	value[valcnt] = content_types[i].code;
	valcnt++;
      } else {
	warn("W: unknown content-type '%s'\n",arg);
      }
    }

    if (!p || key == COAP_OPTION_CONTENT_TYPE)
      break;
    
    q = p+1;
  }

  for (i = 0; i < valcnt; ++i) {
    node = new_option_node(key, coap_encode_var_bytes(buf, value[i]), buf);
    if (node)
      coap_insert( &optlist, node, order_opts );
  }
}

void
cmdline_uri(char *arg) {
  unsigned char portbuf[2];

  if (proxy.length) {		/* create Proxy-Uri from argument */

    coap_insert( &optlist, 
		 new_option_node(COAP_OPTION_PROXY_URI,
				 strlen(arg), (unsigned char *)arg),
		 order_opts);

  } else {			/* split arg into Uri-* options */
    coap_split_uri((unsigned char *)arg, strlen(arg), &uri );

    if (uri.port != COAP_DEFAULT_PORT) {
      coap_insert( &optlist, 
		   new_option_node(COAP_OPTION_URI_PORT,
				   coap_encode_var_bytes(portbuf, uri.port),
				 portbuf),
		   order_opts);    
    }

    if (uri.path.length)
      coap_insert( &optlist, new_option_node(COAP_OPTION_URI_PATH,
					     uri.path.length, uri.path.s),
		   order_opts);
    
    if (uri.query.length)
      coap_insert( &optlist, new_option_node(COAP_OPTION_URI_QUERY,
					     uri.query.length, uri.query.s),
		   order_opts);
  }
}

int
cmdline_blocksize(char *arg) {
  unsigned short size;

 again:
  size = 0;
  while(*arg && *arg != ',')
    size = size * 10 + (*arg++ - '0');
  
  if (*arg == ',') {
    arg++;
    blocknr = size;
    goto again;
  }
  
  if (size)
    blockszx = (coap_fls(size >> 4) - 1) & 0x07;

  return 1;
}

/* Called after processing the options from the commandline to set 
 * Block1 or Block2 depending on method. */
void 
set_blocksize() {
  static unsigned char buf[4];	/* hack: temporarily take encoded bytes */
  unsigned short opt;

  if (method != COAP_REQUEST_DELETE) {
    opt = method == COAP_REQUEST_GET ? COAP_OPTION_BLOCK2 : COAP_OPTION_BLOCK1;

    coap_insert(&optlist, new_option_node(opt,
                coap_encode_var_bytes(buf, (blocknr << 4 | blockszx)), buf),
		order_opts);
  }
}

void
cmdline_subscribe(char *arg) {
  unsigned int ls, s;
  unsigned char duration = COAP_PSEUDOFP_ENCODE_8_4_UP(atoi(arg), ls, s);

  coap_insert( &optlist, new_option_node(COAP_OPTION_SUBSCRIPTION,
					 1, &duration), order_opts );
}

void
cmdline_proxy(char *arg) {
  proxy.length = strlen(arg);
  if ( (proxy.s = coap_malloc(proxy.length + 1)) == NULL) {
    proxy.length = 0;
    return;
  }

  memcpy(proxy.s, arg, proxy.length+1);
}

void
cmdline_token(char *arg) {
  coap_insert( &optlist, new_option_node(COAP_OPTION_TOKEN,
					 strlen(arg),
					 (unsigned char *)arg), order_opts);
}

void
cmdline_option(char *arg) {
  unsigned int num = 0;

  while (*arg && *arg != ',') {
    num = num * 10 + (*arg - '0');
    ++arg;
  }
  if (*arg == ',')
    ++arg;

  coap_insert( &optlist, new_option_node(num,
					 strlen(arg),
					 (unsigned char *)arg), order_opts);
}

extern int  check_segment(const unsigned char *s, size_t length);
extern void decode_segment(const unsigned char *seg, size_t length, unsigned char *buf);

int
cmdline_input(char *text, str *buf) {
  int len;
  len = check_segment((unsigned char *)text, strlen(text));

  if (len < 0)
    return 0;

  buf->s = (unsigned char *)coap_malloc(len);
  if (!buf->s)
    return 0;

  buf->length = len;
  decode_segment((unsigned char *)text, strlen(text), buf->s);
  return 1;
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

coap_context_t *
get_context(const char *node, const char *port) {
  coap_context_t *ctx = NULL;  
  int s;
  struct addrinfo hints;
  struct addrinfo *result, *rp;

  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
  hints.ai_socktype = SOCK_DGRAM; /* Coap uses UDP */
  hints.ai_flags = AI_PASSIVE | AI_NUMERICHOST | AI_NUMERICSERV | AI_ALL;
  
  s = getaddrinfo(node, port, &hints, &result);
  if ( s != 0 ) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
    return NULL;
  } 

  /* iterate through results until success */
  for (rp = result; rp != NULL; rp = rp->ai_next) {
    coap_address_t addr;

    if (rp->ai_addrlen <= sizeof(addr.addr)) {
      coap_address_init(&addr);
      addr.size = rp->ai_addrlen;
      memcpy(&addr.addr, rp->ai_addr, rp->ai_addrlen);

      ctx = coap_new_context(&addr);
      if (ctx) {
	/* TODO: output address:port for successful binding */
	goto finish;
      }
    }
  }
  
  fprintf(stderr, "no context available for interface '%s'\n", node);

 finish:
  freeaddrinfo(result);
  return ctx;
}

int
main(int argc, char **argv) {
  coap_context_t  *ctx = NULL;
  coap_address_t dst;
  static char addr[INET6_ADDRSTRLEN];
  void *addrptr = NULL;
  fd_set readfds;
  struct timeval tv;
  int result;
  coap_tick_t now, max_wait;
  coap_queue_t *nextpdu;
  coap_pdu_t  *pdu;
  static str server;
  unsigned short port = COAP_DEFAULT_PORT;
  char port_str[NI_MAXSERV] = "0";
  int opt, res;
  char *group = NULL;
  coap_log_t log_level = LOG_WARN;
  int flags = 0;

#define FLAGS_BLOCK 0x01

  while ((opt = getopt(argc, argv, "Nb:e:f:g:m:p:s:t:o:v:A:B:O:P:T:")) != -1) {
    switch (opt) {
    case 'b' :
      if (cmdline_blocksize(optarg))      
	flags |= FLAGS_BLOCK;
      break;
    case 'B' :
      wait_seconds = atoi(optarg);
      break;
    case 'e' : 
      if (!cmdline_input(optarg,&payload))
	payload.length = 0;     
      break;
    case 'f' :
      if (!cmdline_input_from_file(optarg,&payload))
	payload.length = 0;
      break;
    case 'g' :
      group = optarg;
      break;
    case 'p' :
      strncpy(port_str, optarg, NI_MAXSERV-1);
      port_str[NI_MAXSERV - 1] = '\0';
      break;
    case 'm' :
      method = cmdline_method(optarg);
      break;
    case 'N' :
      msgtype = COAP_MESSAGE_NON;
      break;
    case 's' :
      cmdline_subscribe(optarg);
      break;
    case 'o' :
      output_file.length = strlen(optarg);
      output_file.s = (unsigned char *)coap_malloc(output_file.length + 1);
      
      if (!output_file.s) {
	fprintf(stderr, "cannot set output file: insufficient memory\n");
	exit(-1);
      } else {
	/* copy filename including trailing zero */
	memcpy(output_file.s, optarg, output_file.length + 1);
      }
      break;
    case 'A' :
      cmdline_content_type(optarg,COAP_OPTION_ACCEPT);
      break;
    case 't' :
      cmdline_content_type(optarg,COAP_OPTION_CONTENT_TYPE);
      break;
    case 'O' :
      cmdline_option(optarg);
      break;
    case 'P' :
      cmdline_proxy(optarg);
      break;
    case 'T' :
      cmdline_token(optarg);
      break;
    case 'v' :
      log_level = strtol(optarg, NULL, 10);
      break;
    default:
      usage( argv[0], PACKAGE_VERSION );
      exit( 1 );
    }
  }

  coap_set_log_level(log_level);

  if ( optind < argc )
    cmdline_uri( argv[optind] );
  else {
    usage( argv[0], PACKAGE_VERSION );
    exit( 1 );
  }

  if (proxy.length) {
    server = proxy;
  } else {
    server = uri.host;
    port = uri.port;
  }

  /* resolve destination address where server should be sent */
  res = resolve_address(&server, &dst.addr.sa);

  if (res < 0) {
    fprintf(stderr, "failed to resolve address\n");
    exit(-1);
  }

  dst.size = res;
  dst.addr.sin.sin_port = htons(port);

  /* add Uri-Host if server address differs from uri.host */
  
  switch (dst.addr.sa.sa_family) {
  case AF_INET: 
    addrptr = &dst.addr.sin.sin_addr;

    /* create context for IPv4 */
    ctx = get_context("0.0.0.0", port_str);
    break;
  case AF_INET6:
    addrptr = &dst.addr.sin6.sin6_addr;

    /* create context for IPv6 */
    ctx = get_context("::", port_str);
    break;
  default:
    ;
  }

  if (!ctx) {
    coap_log(LOG_EMERG, "cannot create context\n");
    return -1;
  }

  coap_register_option(ctx, COAP_OPTION_BLOCK2);
  coap_register_response_handler(ctx, message_handler);

  /* join multicast group if requested at command line */
  if (group)
    join(ctx, group);

  /* construct CoAP message */

  if (addrptr
      && (inet_ntop(dst.addr.sa.sa_family, addrptr, addr, sizeof(addr)) != 0)
      && (strlen(addr) != uri.host.length 
	  || memcmp(addr, uri.host.s, uri.host.length) != 0)) {
      /* add Uri-Host */

    coap_insert(&optlist, new_option_node(COAP_OPTION_URI_HOST,
					  uri.host.length, uri.host.s),
		order_opts);
  }

  /* set block option if requested at commandline */
  if (flags & FLAGS_BLOCK)
    set_blocksize();

  if (! (pdu = coap_new_request(ctx, method, optlist)))
    return -1;

#ifndef NDEBUG
  if (LOG_DEBUG <= coap_get_log_level()) {
    unsigned char buf[COAP_MAX_PDU_SIZE];
    debug("sending CoAP request: ");
    print_readable( (unsigned char *)pdu->hdr, pdu->length, buf, COAP_MAX_PDU_SIZE);
    printf("%s\n",buf);
  }
#endif

  if (pdu->hdr->type == COAP_MESSAGE_CON)
    coap_send_confirmed(ctx, &dst, pdu);
  else 
    coap_send(ctx, &dst, pdu);

  coap_ticks(&max_wait);
  max_wait += wait_seconds * COAP_TICKS_PER_SECOND;
  debug("timeout is set to %d seconds\n", wait_seconds);

  while ( !(ready && coap_can_exit(ctx)) ) {
    FD_ZERO(&readfds);
    FD_SET( ctx->sockfd, &readfds );

    nextpdu = coap_peek_next( ctx );

    coap_ticks(&now);
    while ( nextpdu && nextpdu->t <= now ) {
      coap_retransmit( ctx, coap_pop_next( ctx ));
      nextpdu = coap_peek_next( ctx );
    }

    if (nextpdu && nextpdu->t < max_wait) { /* set timeout if there is a pdu to send */
      tv.tv_usec = ((nextpdu->t - now) % COAP_TICKS_PER_SECOND) << 10;
      tv.tv_sec = (nextpdu->t - now) / COAP_TICKS_PER_SECOND;
    } else {			/* use default timeout otherwise */
      tv.tv_usec = ((max_wait - now) % COAP_TICKS_PER_SECOND) << 10;;
      tv.tv_sec = (max_wait - now) / COAP_TICKS_PER_SECOND;
    }

    result = select(ctx->sockfd + 1, &readfds, 0, 0, &tv);

    if ( result < 0 ) {		/* error */
      perror("select");
    } else if ( result > 0 ) {	/* read from socket */
      if ( FD_ISSET( ctx->sockfd, &readfds ) ) {
	coap_read( ctx );	/* read received data */
	coap_dispatch( ctx );	/* and dispatch PDUs from receivequeue */
      }
    } else { /* timeout */
      coap_ticks(&now);
      if (max_wait <= now) {
	info("timeout\n");
	break;
      }
    }
  }

  close_output();

  coap_free_context( ctx );

  return 0;
}
