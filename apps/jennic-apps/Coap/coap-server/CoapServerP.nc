#include <IPDispatch.h>
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#include "blip_printf.h"

#include "net.h"
#include "resource.h"

#ifndef COAP_SERVER_PORT
#define COAP_SERVER_PORT COAP_DEFAULT_PORT
#endif

module CoapServerP {
  uses {
    interface Boot;
#ifdef COAP_SERVER_ENABLED
    interface CoAPServer;
#endif
  }

} implementation {

  event void Boot.booted() {
#ifdef COAP_SERVER_ENABLED
    // needs to be before registerResource to setup context:
    call CoAPServer.setupContext(COAP_SERVER_PORT);
    call CoAPServer.registerResources();
#endif
  }

}
