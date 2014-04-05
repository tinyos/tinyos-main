configuration RF212OffC{
  provides interface Init;
}
implementation{
  components RF212OffP, HplRF212C, BusyWaitMicroC;
  
  Init = RF212OffP;

  RF212OffP.SELN -> HplRF212C.SELN;
  RF212OffP.SpiResource -> HplRF212C.SpiResource;
  RF212OffP.FastSpiByte -> HplRF212C;

  RF212OffP.SLP_TR -> HplRF212C.SLP_TR;
  RF212OffP.RSTN -> HplRF212C.RSTN;

  RF212OffP.BusyWait -> BusyWaitMicroC;
}
