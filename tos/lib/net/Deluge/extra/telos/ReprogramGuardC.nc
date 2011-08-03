#include "Msp430Adc12.h"


configuration ReprogramGuardC
{
  provides interface ReprogramGuard;
}

implementation
{
  components ReprogramGuardP;
  ReprogramGuard = ReprogramGuardP;

  components new Msp430Adc12ClientAutoRVGC() as Adc;
  Adc.AdcConfigure -> ReprogramGuardP.VoltageConfigure;

  ReprogramGuardP.Resource -> Adc;
  ReprogramGuardP.Sample -> Adc;
}
