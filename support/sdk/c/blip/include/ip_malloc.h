#ifndef NO_IP_MALLOC
#ifndef IP_MALLOC_H_
#define IP_MALLOC_H_

#include <stdint.h>

// align on this number of byte boundarie#s
#define IP_MALLOC_ALIGN   2
#define IP_MALLOC_LEN     0x0fff
#define IP_MALLOC_FLAGS   0x7000
#define IP_MALLOC_INUSE   0x8000
#define IP_MALLOC_HEAP_SIZE 1500

extern uint8_t heap[IP_MALLOC_HEAP_SIZE];
typedef uint16_t bndrt_t;

void ip_malloc_init();
void *ip_malloc(uint16_t sz);
void ip_free(void *ptr);
uint16_t ip_malloc_freespace();

#ifndef PC
#define malloc(X) ip_malloc(X)
#define free(X)   ip_free(X)
#endif

#endif
#endif
