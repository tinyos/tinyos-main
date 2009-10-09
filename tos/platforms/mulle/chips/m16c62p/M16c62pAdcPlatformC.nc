module M16c62pAdcPlatformC
{
  provides interface M16c62pAdcPlatform;
}
implementation
{
  async command void M16c62pAdcPlatform.adcOn()
  {
    // turn on AVcc 
    PD7.BIT.PD7_6 = 1;
    P7.BIT.P7_6 = 1;
		
    // turn on AVref 
    PD3.BIT.PD3_1 = 1;
    P3.BIT.P3_1 = 1;
  }
  
  async command void M16c62pAdcPlatform.adcOff()
  {
//    // turn off AVcc 
//    PD7.BIT.PD7_6 = 0;
//    P7.BIT.P7_6 = 0;
//		
//    // turn off AVref 
//    PD3.BIT.PD3_1 = 0;
//    P3.BIT.P3_1 = 0;
  }
}