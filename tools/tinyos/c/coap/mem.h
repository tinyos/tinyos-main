/* mem.h -- CoAP memory handling
 *          Currently, this is just a dummy for malloc/free
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#ifndef _COAP_MEM_H_
#define _COAP_MEM_H_

#include <stdlib.h>

#define coap_malloc(size) malloc(size)
#define coap_free(size) free(size)

#endif /* _COAP_MEM_H_ */
