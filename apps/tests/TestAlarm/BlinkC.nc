// $Id: BlinkC.nc,v 1.4 2006-12-12 18:22:49 vlahan Exp $

configuration BlinkC
{
}
implementation
{
  components MainC, BlinkM, LedsC, new AlarmMilliC() as AlarmC;
  BlinkM.Boot -> MainC;
  
  MainC.SoftwareInit -> AlarmC;
  BlinkM.Leds -> LedsC;
  BlinkM.Alarm -> AlarmC;
}

