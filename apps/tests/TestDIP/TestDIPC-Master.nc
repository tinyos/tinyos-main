
configuration TestDIPC {

}

implementation {
  components TestDIPP;
  components LedsC as LedsC;
  TestDIPP.Leds -> LedsC;

  components DisseminationC;
  TestDIPP.StdControl -> DisseminationC;
  /*
  components new DisseminatorC(uint32_t, 0x1) as Dissem1;
  TestDIPP.DisseminationValue1 -> Dissem1;
  TestDIPP.DisseminationUpdate1 -> Dissem1;
  */

  // ... DISSEMINATORS

  components MainC;
  TestDIPP.Boot -> MainC;

  components SerialActiveMessageC;
  components new SerialAMSenderC(0xAB);
  TestDIPP.SerialSend -> SerialAMSenderC;
  TestDIPP.SerialControl -> SerialActiveMessageC;
}
