
#include <Ieee154.h>

interface Ieee154Address {
  command ieee154_panid_t getPanId();
  command ieee154_saddr_t getShortAddr();
  command ieee154_laddr_t getExtAddr();
  command error_t setShortAddr(ieee154_saddr_t addr);

  event void changed();

}
