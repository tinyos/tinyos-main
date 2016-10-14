#include <iprouting.h>

#include "tinyos_coap_resources.h"

configuration CoapServerC {

} implementation {
  components MainC;
  components LedsC;
  components CoapServerP;
  components LibCoapAdapterC;
  components IPStackC;

  CoapServerP.Boot -> MainC;

#ifdef COAP_SERVER_ENABLED
  components CoapUdpServerC;
  components new UdpSocketC() as UdpServerSocket;
  CoapServerP.CoAPServer -> CoapUdpServerC;
  CoapUdpServerC.LibCoapServer -> LibCoapAdapterC.LibCoapServer;
  LibCoapAdapterC.UDPServer -> UdpServerSocket;

#ifdef COAP_RESOURCE_LED
  components new CoapLedResourceC(INDEX_LED) as CoapLedResource;
  CoapLedResource.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_LED]  -> CoapLedResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_ROUTE
  components new CoapRouteResourceC(uint16_t, INDEX_ROUTE) as CoapReadRouteResource;
  CoapReadRouteResource.ForwardingTable -> IPStackC;
  CoapUdpServerC.CoapResource[INDEX_ROUTE] -> CoapReadRouteResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_COUNTER
  components new CoapCounterResourceC(INDEX_COUNTER) as CoapCounterResource;
  CoapUdpServerC.CoapResource[INDEX_COUNTER] -> CoapCounterResource.CoapResource;
#endif

#endif

  }
