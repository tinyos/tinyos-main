configuration RF212OffC{
  provides interface Init;
}
implementation{
	components RF212OffP, HplRF212PinsC, BusyWaitMicroC;
  
  Init = RF212OffP;

	RF212OffP.SELN -> HplRF212PinsC.SELN;
	RF212OffP.SpiResource -> HplRF212PinsC.SpiResource;
	RF212OffP.FastSpiByte -> HplRF212PinsC;

	RF212OffP.SLP_TR -> HplRF212PinsC.SLP_TR;
	RF212OffP.RSTN -> HplRF212PinsC.RSTN;

  RF212OffP.BusyWait -> BusyWaitMicroC;
}
