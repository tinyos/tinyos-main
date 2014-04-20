#include "CC2420.h"

configuration CC2420ControlC
{
  provides interface CC2420Config;
  provides interface Read<uint16_t> as ReadRssi;
}

implementation
{
  components MainC, SimMoteP, CC2420ControlP;
  components CpmModelC;

  CC2420Config = CC2420ControlP;
  ReadRssi = CpmModelC;

  MainC.SoftwareInit -> CC2420ControlP;
  CC2420ControlP.SimMote -> SimMoteP;

  components LocalIeeeEui64C;
  CC2420ControlP.LocalIeeeEui64 -> LocalIeeeEui64C;
}
