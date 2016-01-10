#ifndef JN516_COAP_PLATFORM_H_
#define JN516_COAP_PLATFORM_H_

#include "lib6lowpan/ip_malloc.h"

#define coap_malloc(size) ip_malloc(size)
#define coap_free(size) ip_free(size)

#define uthash_malloc(size) ip_malloc(size)
#define uthash_free(ptr,size) ip_free(ptr)

#endif

