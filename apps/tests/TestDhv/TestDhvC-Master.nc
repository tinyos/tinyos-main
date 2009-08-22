#include "TestDhv.h"

configuration TestDhvC {

}

implementation {
  components TestDhvP;
  components LedsC as LedsC;
  TestDhvP.Leds -> LedsC;

  components DisseminationC;
  TestDhvP.StdControl -> DisseminationC;
  /*
  components new DisseminatorC(uint32_t, 0x1) as Dissem1;
  TestDhvP.DisseminationValue1 -> Dissem1;
  TestDhvP.DisseminationUpdate1 -> Dissem1;
  */

  // ... DISSEMINATORS

  components MainC;
  TestDhvP.Boot -> MainC;

  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_DHV_TEST_MSG);
  TestDhvP.SerialSend -> SerialAMSenderC;
  TestDhvP.SerialControl -> SerialActiveMessageC;
}
