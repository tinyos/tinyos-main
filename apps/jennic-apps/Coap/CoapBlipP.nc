#include <IPDispatch.h>
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include "blip_printf.h"

module CoapBlipP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface Leds;
  }

} implementation {

  event void Boot.booted() {

    call RadioControl.start();
    printf("booted %i start\n", TOS_NODE_ID);

  }

  event void RadioControl.startDone(error_t e) {
    printf("radio startDone: %i\n", TOS_NODE_ID);
  }

  event void RadioControl.stopDone(error_t e) {
  }

}
