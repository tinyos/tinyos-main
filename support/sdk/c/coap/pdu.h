/* pdu.h -- CoAP message structure
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

#ifndef _PDU_H_
#define _PDU_H_

#include "config.h"
#include "list.h"
#include "uri.h"

/* pre-defined constants that reflect defaults for CoAP */

#define COAP_DEFAULT_RESPONSE_TIMEOUT  1 /* response timeout in seconds */
#define COAP_DEFAULT_MAX_RETRANSMIT    5 /* max number of retransmissions */
#define COAP_DEFAULT_PORT          61616 /* CoAP default UDP port */
#define COAP_DEFAULT_MAX_AGE          60 /* default maximum object lifetime in seconds */
#define COAP_MAX_PDU_SIZE           700 /* maximum size of a CoAP PDU */

#define COAP_DEFAULT_VERSION           1 /* version of CoAP supported */
#define COAP_DEFAULT_SCHEME        "coap" /* the default scheme for CoAP URIs */
#define COAP_DEFAULT_URI_WELLKNOWN ".well-known/core" /* well-known resources URI */

/* CoAP message types */

#define COAP_MESSAGE_CON               0 /* confirmable message (requires ACK/RST) */
#define COAP_MESSAGE_NON               1 /* non-confirmable message (one-shot message) */
#define COAP_MESSAGE_ACK               2 /* used to acknowledge confirmable messages */
#define COAP_MESSAGE_RST               3 /* indicates error in received messages */

/* CoAP request methods */

#define COAP_REQUEST_GET       1
#define COAP_REQUEST_POST      2
#define COAP_REQUEST_PUT       3
#define COAP_REQUEST_DELETE    4

/* CoAP option types (be sure to update check_critical when adding options */

#define COAP_OPTION_CONTENT_TYPE  1 /* C, 8-bit uint, 1 B, 0 (text/plain) */
#define COAP_OPTION_MAXAGE        2 /* E, variable length, 1--4 B, 60 Seconds */
#define COAP_OPTION_URI_SCHEME    3 /* C, String, 1-270 B, "coap" */
#define COAP_OPTION_ETAG          4 /* E, sequence of bytes, 1-4 B, - */
#define COAP_OPTION_URI_AUTHORITY 5 /* C, String, 1-270 B, "" */
#define COAP_OPTION_LOCATION      6 /* E, String, 1-270 B, - */
#define COAP_OPTION_URI_PATH      9 /* C, String, 1-270 B, "" */
#define COAP_OPTION_TOKEN        11 /* C, Sequence of Bytes, 1-2 B, - */
#define COAP_OPTION_URI_QUERY    15 /* C, String, 1-270 B, "" */

/* option types from draft-hartke-coap-observe-01 */

#define COAP_OPTION_SUBSCRIPTION 10 /* E, Duration, 1 B, 0 */

/* selected option types from draft-bormann-coap-misc-04 */

#define COAP_OPTION_ACCEPT        8 /* E  Sequence of Bytes, 1-n B, - */
#define COAP_OPTION_BLOCK        13 /* C, unsigned integer, 1--3 B, 0 */
#define COAP_OPTION_NOOP         14 /* no-op for fenceposting */

/* CoAP result codes (HTTP-Code / 100 * 40 + HTTP-Code % 100) */

#define COAP_RESPONSE_CODE(N)  (((N)/100 << 5) | (N)%100)
#define COAP_RESPONSE_100       40   /* 100 Continue */
#define COAP_RESPONSE_200       80   /* 200 OK */
#define COAP_RESPONSE_201       81   /* 201 Created */
#define COAP_RESPONSE_304      124   /* 304 Not Modified */
#define COAP_RESPONSE_400      160   /* 400 Bad Request */
#define COAP_RESPONSE_404      164   /* 404 Not Found */
#define COAP_RESPONSE_405      165   /* 405 Method Not Allowed */
#define COAP_RESPONSE_415      175   /* 415 Unsupported Media Type */
#define COAP_RESPONSE_500      200   /* 500 Internal Server Error */
#define COAP_RESPONSE_503      203   /* 503 Service Unavailable */
#define COAP_RESPONSE_504      204   /* 504 Gateway Timeout */
#define COAP_RESPONSE_X_240    240   /* Token Option required by server */
#define COAP_RESPONSE_X_241    241   /* Uri-Authority Option required by server */
#define COAP_RESPONSE_X_242    242   /* Critical Option not supported */

#define COAP_SPLITPHASE       300   /* Code for telling TinyOS that the splitphase resource has successfully started */

/* CoAP media type encoding */

#define COAP_MEDIATYPE_TEXT_PLAIN                     0 /* text/plain (UTF-8) */
#define COAP_MEDIATYPE_TEXT_XML                       1 /* text/xml (UTF-8) */
#define COAP_MEDIATYPE_TEXT_CSV                       2 /* text/csv (UTF-8) */
#define COAP_MEDIATYPE_TEXT_HTML                      3 /* text/html (UTF-8) */
#define COAP_MEDIATYPE_IMAGE_GIF                     21 /* image/gif */
#define COAP_MEDIATYPE_IMAGE_JPEG                    22 /* image/jpeg */
#define COAP_MEDIATYPE_IMAGE_PNG                     23 /* image/png */
#define COAP_MEDIATYPE_IMAGE_TIFF                    24 /* image/tiff */
#define COAP_MEDIATYPE_AUDIO_RAW                     25 /* audio/raw */
#define COAP_MEDIATYPE_VIDEO_RAW                     26 /* video/raw */
#define COAP_MEDIATYPE_APPLICATION_LINK_FORMAT       40 /* application/link-format */
#define COAP_MEDIATYPE_APPLICATION_XML               41 /* application/xml */
#define COAP_MEDIATYPE_APPLICATION_OCTET_STREAM      42 /* application/octet-stream */
#define COAP_MEDIATYPE_APPLICATION_RDF_XML           43 /* application/rdf+xml */
#define COAP_MEDIATYPE_APPLICATION_SOAP_XML          44 /* application/soap+xml  */
#define COAP_MEDIATYPE_APPLICATION_ATOM_XML          45 /* application/atom+xml  */
#define COAP_MEDIATYPE_APPLICATION_XMPP_XML          46 /* application/xmpp+xml  */
#define COAP_MEDIATYPE_APPLICATION_EXI               47 /* application/exi  */
#define COAP_MEDIATYPE_APPLICATION_X_BXML            48 /* application/x-bxml  */
#define COAP_MEDIATYPE_APPLICATION_FASTINFOSET       49 /* application/fastinfoset  */
#define COAP_MEDIATYPE_APPLICATION_SOAP_FASTINFOSET  50 /* application/soap+fastinfoset  */
#define COAP_MEDIATYPE_APPLICATION_JSON              51 /* application/json  */

#define COAP_MEDIATYPE_ANY                         0xff /* any media type */

/* CoAP transaction id */
typedef unsigned short coap_tid_t;
/* typedef int coap_tid_t;*/
#define COAP_INVALID_TID -1

#ifdef WORDS_BIGENDIAN
typedef struct {
  unsigned int version:2;	/* protocol version */
  unsigned int type:2;		/* type flag */
  unsigned int optcnt:4;	/* number of options following the header */
  unsigned int code:8;	        /* request method (value 1--10) or response code (value 40-255) */
  unsigned short id;		/* transaction id */
} coap_hdr_t;
#else
typedef struct {
  unsigned int optcnt:4;	/* number of options following the header */
  unsigned int type:2;		/* type flag */
  unsigned int version:2;	/* protocol version */
  unsigned int code:8;	        /* request method (value 1--10) or response code (value 40-255) */
  unsigned short id;		/* transaction id (network byte order!) */
} coap_hdr_t;
#endif

#ifdef WORDS_BIGENDIAN
typedef union {
  struct {		        /* short form, to be used when length < 15 */
    unsigned int delta:4;      /* option type (expressed as delta) */
    unsigned int length:4;	/* number of option bytes (15 indicates extended form) */
    /* 0--14 bytes options */
  } sval;
  struct {			/* extended form, to be used when lengt==15 */
    unsigned int delta:4;      /* option type (expressed as delta) */
    unsigned int flag:4;	/* must be 15! */
    unsigned int length:8;	/* length - 15 */
    /* 15--270 bytes options */
  } lval;
} coap_opt_t;
#else
typedef union {
  struct {		        /* short form, to be used when length < 15 */
    unsigned int length:4;	/* number of option bytes (15 indicates extended form) */
    unsigned int delta:4;      /* option type (expressed as delta) */
    /* 0--14 bytes options */
  } sval;
  struct {			/* extended form, to be used when lengt==15 */
    unsigned int flag:4;	/* must be 15! */
    unsigned int delta:4;      /* option type (expressed as delta) */
    unsigned int length:8;	/* length - 15 */
    /* 15--270 bytes options */
  } lval;
} coap_opt_t;
#endif

#define COAP_OPT_SVAL(opt) (opt).sval
#define COAP_OPT_LVAL(opt) (opt).lval
#define COAP_OPT_ISEXTENDED(opt) (COAP_OPT_LVAL(opt).flag == 15)

/* these macros should be used to access fields from coap_opt_t */
#define COAP_OPT_DELTA(opt) COAP_OPT_SVAL(opt).delta
#define COAP_OPT_SETDELTA(opt,val) COAP_OPT_SVAL(opt).delta = (val)

#define COAP_OPT_LENGTH(opt) \
  ( COAP_OPT_ISEXTENDED(opt) ? COAP_OPT_LVAL(opt).length + 15 : COAP_OPT_SVAL(opt).length )

#define COAP_OPT_SETLENGTH(opt,val)		\
  if ( (val) < 15 )				\
    COAP_OPT_SVAL(opt).length = (val) & 0x0f;	\
  else {								\
    COAP_OPT_LVAL(opt).length = ((val) - 15) & 0xff;			\
    COAP_OPT_LVAL(opt).flag = 15;					\
  }

#define COAP_OPT_VALUE(opt)						\
  ( (unsigned char *)&(opt) + ( COAP_OPT_ISEXTENDED(opt) ? 2 : 1 ) )

/* do not forget to adjust this when coap_opt_t is changed! */
#define COAP_OPT_SIZE(opt) ( COAP_OPT_LENGTH(opt) + ( COAP_OPT_ISEXTENDED(opt) ? 2: 1 ) )

/**
 * Structures for more convenient handling of options. (To be used with ordered
 * coap_list_t.) The option's data will be added to the end of the coap_option 
 * structure (see macro COAP_OPTION_DATA).
 */
typedef struct {
  unsigned short key;		/* the option key (no delta coding) */
  unsigned int length;
#if 0
  union {
    unsigned int n;   /* unsigned integer (1--4 bytes) */
    unsigned char fp; /* pseudo-fp (currently, only (8,4) supported */
    unsigned char *d; /* date (4--6 bytes) */
    unsigned char *s; /* string (or sequence of bytes) */
  } value;
#endif
} coap_option;

#define COAP_OPTION_KEY(option) (option).key
#define COAP_OPTION_LENGTH(option) (option).length
#if 0
#define COAP_OPTION_UINT(option) (option).value.n
#define COAP_OPTION_PSEUDO_FP(option) (option).value.fp
#define COAP_OPTION_DATE(option) (option).value.d
#define COAP_OPTION_STRING(option) (option).value.s
#endif
#define COAP_OPTION_DATA(option) ((unsigned char *)&(option) + sizeof(coap_option))

/** Header structure for CoAP PDUs */

typedef struct {
  coap_hdr_t *hdr;
  unsigned short length;	/* PDU length (including header, options, data)  */
  coap_list_t *options;		/* parsed options */
  unsigned char *data;		/* payload */
} coap_pdu_t;

/** Options in coap_pdu_t are accessed with the macro COAP_OPTION. */
#define COAP_OPTION(node) ((coap_option *)(node)->options)

/** 
 * Creates a new CoAP PDU. The object is created on the heap and must be released
 * using delete_pdu();
 */

coap_pdu_t *coap_new_pdu();
void coap_delete_pdu(coap_pdu_t *);

#if 0
int coap_encode_pdu(coap_pdu_t *);
#endif

/** 
 * Adds option of given type to pdu that is passed as first parameter. coap_add_option() 
 * destroys the PDU's data, so coap_add_data must be called after all options have been
 * added.
 */
int coap_add_option(coap_pdu_t *pdu, unsigned char type, unsigned int len, const unsigned char *data);
coap_opt_t *coap_check_option(coap_pdu_t *pdu, unsigned char type);

/** 
 * Checks for critical options that we do not know, as requests
 * containing unknown critical options must be discarded. The function
 * returns a pointer to the first unknown critical option in the given
 * pdu (hence with delta-encoded type) or NULL when no unknown critical
 * option was found. The return value contains the type code of the
 * rejected option, or zero if none was found.
 */
int coap_check_critical(coap_pdu_t *pdu, coap_opt_t **option);

/** 
 * Adds given data to the pdu that is passed as first parameter. Note that the PDU's 
 * data is destroyed by coap_add_option().
 */
int coap_add_data(coap_pdu_t *pdu, unsigned int len, const unsigned char *data);

/**
 * Retrieves the length and data pointer of specified PDU. Returns 0 on error
 * or 1 if *len and *data have correct values. Note that these values are
 * destroyed with the pdu.
 */
int coap_get_data(coap_pdu_t *pdu, unsigned int *len, unsigned char **data);

/**
 * Fills the given coap_uri_t object with the request URI components from 
 * the PDU.
 * @param pdu the PDU 
 * @param result the URI object to update
 * @return 1 if result has been updated, 0 otherwise, i.e. in case of error
 */
int coap_get_request_uri(coap_pdu_t *pdu, coap_uri_t *result);

#endif /* _PDU_H_ */
