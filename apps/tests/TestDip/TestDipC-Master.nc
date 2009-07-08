#include "TestDip.h"

configuration TestDipC {

}

implementation {
  components TestDipP;
  components LedsC as LedsC;
  TestDipP.Leds -> LedsC;

  components DisseminationC;
  TestDipP.StdControl -> DisseminationC;
  /*
  components new DisseminatorC(uint32_t, 0x1) as Dissem1;
  TestDipP.DisseminationValue1 -> Dissem1;
  TestDipP.DisseminationUpdate1 -> Dissem1;
  */

  // ... DISSEMINATORS

  components MainC;
  TestDipP.Boot -> MainC;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_TESTDIP);
  TestDipP.SerialSend -> SerialAMSenderC;
  TestDipP.SerialControl -> SerialActiveMessageC;
}
