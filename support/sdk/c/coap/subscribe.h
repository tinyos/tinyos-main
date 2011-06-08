/* subscribe.h -- subscription handling for CoAP 
 *                see draft-hartke-coap-observe-01
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



#ifndef _COAP_SUBSCRIBE_H_
#define _COAP_SUBSCRIBE_H_

#include "uri.h"
#include "list.h"
#include "pdu.h"
#include "net.h"

typedef unsigned long coap_key_t;

/** Used to indicate that a hashkey is invalid. */
#define COAP_INVALID_HASHKEY ((coap_key_t)-1)

typedef struct {
  coap_uri_t *uri;		/* unique identifier; memory is released by coap_delete_resource() */
  str *name;			/* display name of the resource */
  unsigned char mediatype;	/* media type for resource representation */
  unsigned int dirty:1;		/* set to 1 if resource has changed */
  unsigned int writable:1;	/* set to 1 if resource can be changed using PUT */
  unsigned int splitphase:1;	/* set to 1 if resource is split-phase async */
  unsigned int immediately;     /* set to 1 if data is send immediately */
  
  
  /* cache-control */
  unsigned char etag[4];        /* version identifier for this resource 
				 * (zero terminated, first byte is zero if not set). */
  unsigned int maxage;		/* maximum cache time (zero means no Max-age option) */

  /** 
   * Callback function that copies the resource representation into the provided data
   * buffer (PDU payload). finished is set to 1 to indicate that this was the last block 
   * of buflen data for this resource representation, 0 means that data is not finished
   * and a subsequent call with offset updated by buflen would yield more data (i.e. 
   * the M-bit of CoAP's block option must be set if offset and buflen are selected
   * accordingly.
   * When called, buflen must be set to the maximum length of buf that is to be filled 
   * with the mediatype representation of the resource identified by uri. 
   * The mediatype must be set to the requested mediatype of COAP_MEDIATYPE_ANY if
   * none was given. On return, the mediatype will be set to the type that is
   * actually used.
   * The return value indicates the result code that should be used in a response to
   * this function.
   */
  int (*data)(coap_uri_t *uri, unsigned short *tid, unsigned char *mediatype, unsigned int offset, unsigned char *buf, unsigned int *buflen, int *finished, unsigned int method);
} coap_resource_t;

typedef struct {
  coap_key_t resource;		/* hash key for subscribed resource */
#ifndef IDENT_APPNAME
  time_t expires;		/* expiry time of subscription */

#endif
  struct sockaddr_in6 subscriber; /* subscriber's address */
  str token;			  /* subscription token */
} coap_subscription_t;

#define COAP_RESOURCE(node) ((coap_resource_t *)(node)->data)
#define COAP_SUBSCRIPTION(node) ((coap_subscription_t *)(node)->data)

/** Checks subscribed resources for updates and notifies subscribers of changes. */
void coap_check_resource_list(coap_context_t *context);

/** Removes expired subscriptions. */
void coap_check_subscriptions(coap_context_t *context);

/**
 * Adds specified resource to the resource observation list. Returns a
 * unique key for the resource. The alloceted memory is released when
 * the resource is destroyed with coap_delete_resource().
 */
coap_key_t coap_add_resource(coap_context_t *context, coap_resource_t *);

/**
 * Deletes the resource that is identified by key. Returns 1 if the resource was
 * removed, 0 on error (e.g. if no such resource exists). 
 */
int coap_delete_resource(coap_context_t *context, coap_key_t key);

/**
 * Creates a new subscription object filled with the given data. The storage
 * allocated for this object must be released using coap_free(). */
#ifndef IDENT_APPNAME
coap_subscription_t *coap_new_subscription(coap_context_t *context, 
					   const coap_uri_t *resource,
					   const struct sockaddr_in6 *subscriber,
					   time_t expiry);
#endif

/**
 * Adds the given subsription object to the observer list. 
 * @param context The CoAP context
 * @param subscription A new subscription oobject created with coap_new_subscription()
 * @return A unique hash key for this resource or COAP_INVALID_HASHKEY on error.
 * The storage allocated for the subscription object is released when it is
 * removed from the subscription list, unless the function has returned 
 * COAP_INVALID_HASHKEY. In this case, the storage must be released by the 
 * caller of this function.
*/
coap_key_t coap_add_subscription(coap_context_t *context, 
				 coap_subscription_t *subscription);

/**
 * Returns the subscription from subscriber for the resource identified 
 * by hashkey. When token is not NULL the subscription must have the
 * same token.
 * @param context The CoAP context
 * @param hashkey The unique key that identifies the subscription
 * @param subscriber The subscriber's transport address
 * @param token If not NULL, this specifies a token given by the
 *              subscriber to identify its subscription.
 * @return The requested subscription object or NULL when not found.
 */
coap_subscription_t * coap_find_subscription(coap_context_t *context, 
					     coap_key_t hashkey,
					     struct sockaddr_in6 *subscriber,
					     str *token);
/**
 * Removes a subscription from the subscription list stored in context and
 * releases the storage that was allocated for this subscription.
 * @param context The CoAP context.
 * @param haskey The unique key that identifies the subscription to remove. 
 * @return 1 if a subscription was removed, 0 otherwise.
 */
int coap_delete_subscription(coap_context_t *context, 
			     coap_key_t hashkey,
			     struct sockaddr_in6 *subscriber);

/** Returns a unique hash for the specified URI or COAP_INVALID_HASHKEY on error. */
coap_key_t coap_uri_hash(const coap_uri_t *uri);


/** Returns a unique hash for the specified subscription or COAP_INVALID_HASHKEY on error. */
coap_key_t coap_subscription_hash(coap_subscription_t *subscription);

/** Returns the resource identified by key or NULL if not found. */
coap_resource_t *coap_get_resource_from_key(coap_context_t *ctx, coap_key_t key);

/** Returns the resource identified by uri or NULL if not found. */
coap_resource_t *coap_get_resource(coap_context_t *ctx, coap_uri_t *uri);

#endif /* _COAP_SUBSCRIBE_H_ */
