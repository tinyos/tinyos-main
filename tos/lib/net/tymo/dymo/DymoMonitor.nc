#include "message.h"

interface DymoMonitor {

  event void msgReceived(message_t * msg);

  event void msgSent(message_t * msg);

  event void routeDiscovered(uint32_t delay, addr_t target);

}
