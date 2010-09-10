
#include <Ieee154.h>

interface Ieee154Packet {
  /* 
   * Find the IEEE154 source address in the frame, and copy it to the
   * ieee154_addr_t passed in.
   */
  command error_t source(message_t *msg, ieee154_addr_t *addr);
  command error_t destination(message_t *msg, ieee154_addr_t *addr);
}
