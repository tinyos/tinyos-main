configuration LedsIntensityC
{
  provides interface StdControl;
  provides interface LedsIntensity;
}
implementation
{
  components new LedsIntensityP(), LedsC, MainC;

  StdControl = LedsIntensityP;
  LedsIntensity = LedsIntensityP;

  LedsIntensityP.Leds -> LedsC;
  LedsIntensityP.Boot -> MainC;
}
