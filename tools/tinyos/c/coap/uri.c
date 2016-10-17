/* uri.c -- helper functions for URI treatment
 *
 * Copyright (C) 2010--2012 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#include "config.h"

#if defined(HAVE_ASSERT_H) && !defined(assert)
# include <assert.h>
#endif

#ifndef assert
//#warning "assertions are disabled"
#  define assert(x)
#endif

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "mem.h"
#include "coap_debug.h"
#include "pdu.h"
#include "option.h"
#include "uri.h"

/** 
 * A length-safe version of strchr(). This function returns a pointer
 * to the first occurrence of @p c  in @p s, or @c NULL if not found.
 * 
 * @param s   The string to search for @p c.
 * @param len The length of @p s.
 * @param c   The character to search.
 * 
 * @return A pointer to the first occurence of @p c, or @c NULL 
 * if not found.
 */
static inline unsigned char *
strnchr(unsigned char *s, size_t len, unsigned char c) {
  while (len && *s++ != c)
    --len;
  
  return len ? s : NULL;
}

int
coap_split_uri(unsigned char *str_var, size_t len, coap_uri_t *uri) {
  unsigned char *p, *q;
  int secure = 0, res = 0;

  if (!str_var || !uri)
    return -1;

  memset(uri, 0, sizeof(coap_uri_t));
  uri->port = COAP_DEFAULT_PORT;

  /* search for scheme */
  p = str_var;
  if (*p == '/') {
    q = p;
    goto path;
  }

  q = (unsigned char *)COAP_DEFAULT_SCHEME;
  while (len && *q && tolower(*p) == *q) {
    ++p; ++q; --len;
  }
  
  /* If q does not point to the string end marker '\0', the schema
   * identifier is wrong. */
  if (*q) {
    res = -1;
    goto error;
  }

  /* There might be an additional 's', indicating the secure version: */
  if (len && (secure = tolower(*p) == 's')) {
    ++p; --len;
  }

  q = (unsigned char *)"://";
  while (len && *q && tolower(*p) == *q) {
    ++p; ++q; --len;
  }

  if (*q) {
    res = -2;
    goto error;
  }

  /* p points to beginning of Uri-Host */
  q = p;
  if (len && *p == '[') {	/* IPv6 address reference */
    ++p;
    
    while (len && *q != ']') {
      ++q; --len;
    }

    if (!len || *q != ']' || p == q) {
      res = -3;
      goto error;
    } 

    COAP_SET_STR(&uri->host, q - p, p);
    ++q; --len;
  } else {			/* IPv4 address or FQDN */
    while (len && *q != ':' && *q != '/' && *q != '?') {
      *q = tolower(*q);
      ++q;
      --len;
    }

    if (p == q) {
      res = -3;
      goto error;
    }

    COAP_SET_STR(&uri->host, q - p, p);
  }

  /* check for Uri-Port */
  if (len && *q == ':') {
    p = ++q;
    --len;
    
    while (len && isdigit(*q)) {
      ++q;
      --len;
    }

    if (p < q) {		/* explicit port number given */
      int uri_port = 0;
    
      while (p < q)
	uri_port = uri_port * 10 + (*p++ - '0');

      uri->port = uri_port;
    } 
  }
  
 path:		 /* at this point, p must point to an absolute path */

  if (!len)
    goto end;
  
  if (*q == '/') {
    p = ++q;
    --len;

    while (len && *q != '?') {
      ++q;
      --len;
    }
  
    if (p < q) {
      COAP_SET_STR(&uri->path, q - p, p);
      p = q;
    }
  }

  /* Uri_Query */
  if (len && *p == '?') {
    ++p;
    --len;
    COAP_SET_STR(&uri->query, len, p);
    len = 0;
  }

  end:
  return len ? -1 : 0;
  
  error:
  return res;
}

/** 
 * Calculates decimal value from hexadecimal ASCII character given in
 * @p c. The caller must ensure that @p c actually represents a valid
 * heaxdecimal character, e.g. with isxdigit(3). 
 *
 * @hideinitializer
 */
#define hexchar_to_dec(c) ((c) & 0x40 ? ((c) & 0x0F) + 9 : ((c) & 0x0F))

/** 
 * Decodes percent-encoded characters while copying the string @p seg
 * of size @p length to @p buf. The caller of this function must
 * ensure that the percent-encodings are correct (i.e. the character
 * '%' is always followed by two hex digits. and that @p buf provides
 * sufficient space to hold the result. This function is supposed to
 * be called by make_decoded_option() only.
 * 
 * @param seg     The segment to decode and copy.
 * @param length  Length of @p seg.
 * @param buf     The result buffer.
 */
void
decode_segment(const unsigned char *seg, size_t length, unsigned char *buf) {

  while (length--) {

    if (*seg == '%') {
      *buf = (hexchar_to_dec(seg[1]) << 4) + hexchar_to_dec(seg[2]);
      
      seg += 2; length -= 2;
    } else {
      *buf = *seg;
    }
    
    ++buf; ++seg;
  }
}

/**
 * Runs through the given path (or query) segment and checks if
 * percent-encodings are correct. This function returns @c -1 on error
 * or the length of @p s when decoded.
 */
int 
check_segment(const unsigned char *s, size_t length) {

  size_t n = 0;

  while (length) {
    if (*s == '%') {
      if (length < 2 || !(isxdigit(s[1]) && isxdigit(s[2])))
	return -1;
      
      s += 2;
      length -= 2;
    }

    ++s; ++n; --length;
  }
  
  return n;
}
	 
/** 
 * Writes a coap option from given string @p s to @p buf. @p s should
 * point to a (percent-encoded) path or query segment of a coap_uri_t
 * object.  The created option will have type @c 0, and the length
 * parameter will be set according to the size of the decoded string.
 * On success, this function returns the option's size, or a value
 * less than zero on error. This function must be called from
 * coap_split_path_impl() only.
 * 
 * @param s       The string to decode.
 * @param length  The size of the percent-encoded string @p s.
 * @param buf     The buffer to store the new coap option.
 * @param buflen  The maximum size of @p buf.
 * 
 * @return The option's size, or @c -1 on error.
 *
 * @bug This function does not split segments that are bigger than 270
 * bytes.
 */
int
make_decoded_option(const unsigned char *s, size_t length, 
		    unsigned char *buf, size_t buflen) {
  int res;
  size_t written;

  if (!buflen) {
    debug("make_decoded_option(): buflen is 0!\n");
    return -1;
  }

  res = check_segment(s, length);
  if (res < 0)
    return -1;

  /* write option header using delta 0 and length res */
  written = coap_opt_setheader(buf, buflen, 0, res);

  assert(written <= buflen);

  if (!written)			/* encoding error */
    return -1;

  buf += written;		/* advance past option type/length */
  buflen -= written;

  if (buflen < (size_t)res) {
    debug("buffer too small for option\n");
    return -1;
  }

  decode_segment(s, length, buf);

  return written + res;
}


#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif

typedef void (*segment_handler_t)(unsigned char *, size_t, void *);

/** 
 * Splits the given string into segments. You should call one of the
 * macros coap_split_path() or coap_split_query() instead.
 * 
 * @param parse_iter The iterator used for tokenizing.
 * @param h      A handler that is called with every token.
 * @param data   Opaque data that is passed to @p h when called.
 * 
 * @return The number of characters that have been parsed from @p s.
 */
size_t
coap_split_path_impl(coap_parse_iterator_t *parse_iter,
		     segment_handler_t h, void *data) {
  unsigned char *seg;
  size_t length;
  
  assert(parse_iter);
  assert(h);

  length = parse_iter->n;
  
  while ( (seg = coap_parse_next(parse_iter)) ) {

    /* any valid path segment is handled here: */
    h(seg, parse_iter->segment_length, data);
  }
  
  return length - (parse_iter->n - parse_iter->segment_length);
}

struct cnt_str {
  str buf;
  int n;
};

void
write_option(unsigned char *s, size_t len, void *data) {
  struct cnt_str *state = (struct cnt_str *)data;
  int res;
  assert(state);

  /* skip empty segments and those that consist of only one or two dots */
  if (memcmp(s, "..", min(len,2)) == 0)
    return;
  
  res = make_decoded_option(s, len, state->buf.s, state->buf.length);
  if (res > 0) {
    state->buf.s += res;
    state->buf.length -= res;
    state->n++;
  }
}

int
coap_split_path(const unsigned char *s, size_t length, 
		unsigned char *buf, size_t *buflen) {
  struct cnt_str tmp = { { *buflen, buf }, 0 };
  coap_parse_iterator_t pi;

  coap_parse_iterator_init((unsigned char *)s, length, 
			   '/', (unsigned char *)"?#", 2, &pi);
  coap_split_path_impl(&pi, write_option, &tmp);

  *buflen = *buflen - tmp.buf.length;
  return tmp.n;
}

int
coap_split_query(const unsigned char *s, size_t length, 
		unsigned char *buf, size_t *buflen) {
  struct cnt_str tmp = { { *buflen, buf }, 0 };
  coap_parse_iterator_t pi;

  coap_parse_iterator_init((unsigned char *)s, length, 
			   '&', (unsigned char *)"#", 1, &pi);

  coap_split_path_impl(&pi, write_option, &tmp);

  *buflen = tmp.buf.length;
  return tmp.n;
}

#define URI_DATA(uriobj) ((unsigned char *)(uriobj) + sizeof(coap_uri_t))

coap_uri_t *
coap_new_uri(const unsigned char *uri, unsigned int length) {
  unsigned char *result;

  result = coap_malloc(length + 1 + sizeof(coap_uri_t));

  if (!result)
    return NULL;

  memcpy(URI_DATA(result), uri, length);
  URI_DATA(result)[length] = '\0'; /* make it zero-terminated */

  if (coap_split_uri(URI_DATA(result), length, (coap_uri_t *)result) < 0) {
    free(result);
    return NULL;
  }
  return (coap_uri_t *)result;
}

coap_uri_t *
coap_clone_uri(const coap_uri_t *uri) {
  coap_uri_t *result;

  if ( !uri )
    return  NULL;

  result = (coap_uri_t *)coap_malloc( uri->query.length + uri->host.length +
				      uri->path.length + sizeof(coap_uri_t) + 1);

  if ( !result )
    return NULL;

  memset( result, 0, sizeof(coap_uri_t) );

  result->port = uri->port;

  if ( uri->host.length ) {
    result->host.s = URI_DATA(result);
    result->host.length = uri->host.length;

    memcpy(result->host.s, uri->host.s, uri->host.length);
  }

  if ( uri->path.length ) {
    result->path.s = URI_DATA(result) + uri->host.length;
    result->path.length = uri->path.length;

    memcpy(result->path.s, uri->path.s, uri->path.length);
  }

  if ( uri->query.length ) {
    result->query.s = URI_DATA(result) + uri->host.length + uri->path.length;
    result->query.length = uri->query.length;

    memcpy(result->query.s, uri->query.s, uri->query.length);
  }

  return result;
}

/* hash URI path segments */

/* The function signature of coap_hash() is different from
 * segment_handler_t hence we use this wrapper as safe typecast. */
static inline void
hash_segment(unsigned char *s, size_t len, void *data) {
  coap_hash(s, len, data);
}

int
coap_hash_path(const unsigned char *path, size_t len, coap_key_t key) {
  coap_parse_iterator_t pi;

  if (!path)
    return 0;

  memset(key, 0, sizeof(coap_key_t));

  coap_parse_iterator_init((unsigned char *)path, len, 
			   '/', (unsigned char *)"?#", 2, &pi);
  coap_split_path_impl(&pi, hash_segment, key);

  return 1;
}

/* iterator functions */

coap_parse_iterator_t *
coap_parse_iterator_init(unsigned char *s, size_t n, 
			 unsigned char separator,
			 unsigned char *delim, size_t dlen,
			 coap_parse_iterator_t *pi) {
  assert(pi);
  assert(separator);

  pi->separator = separator;
  pi->delim = delim;
  pi->dlen = dlen;
  pi->pos = s;
  pi->n = n;
  pi->segment_length = 0;

  return pi;
}

unsigned char *
coap_parse_next(coap_parse_iterator_t *pi) {
  unsigned char *p;

  if (!pi)
    return NULL;

  /* proceed to the next segment */
  pi->n -= pi->segment_length;
  pi->pos += pi->segment_length;
  pi->segment_length = 0;

  /* last segment? */
  if (!pi->n || strnchr(pi->delim, pi->dlen, *pi->pos)) {
    pi->pos = NULL;
    return NULL;
  }

  /* skip following separator (the first segment might not have one) */
  if (*pi->pos == pi->separator) {
    ++pi->pos;
    --pi->n;
  }

  p = pi->pos;

  while (pi->segment_length < pi->n && *p != pi->separator &&
	 !strnchr(pi->delim, pi->dlen, *p)) {
    ++p;
    ++pi->segment_length;
  }

  if (!pi->n) {
    pi->pos = NULL;
    pi->segment_length = 0;
  }

  return pi->pos;
}

