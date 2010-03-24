#include "hardware.h"

module PlatformP{
  provides interface Init;
  uses interface Init as MoteClockInit;
  uses interface Init as MoteInit;
  uses interface Init as LedsInit;
}
implementation {
  command error_t Init.init() {
    call MoteClockInit.init();
    call MoteInit.init();
    call LedsInit.init();
    return SUCCESS;
  }

  default command error_t LedsInit.init() { return SUCCESS; }

}
