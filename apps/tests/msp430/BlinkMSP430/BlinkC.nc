// $Id: BlinkC.nc,v 1.2 2006-07-12 16:59:30 scipio Exp $

configuration BlinkC
{
}
implementation
{
  components MainC as Main, BlinkM, LedsC, MSP430TimerC;
  BlinkM.Boot -> Main;
  Main.SoftwareInit -> LedsC;
  BlinkM.Leds -> LedsC;
  BlinkM.TimerControl -> MSP430TimerC.ControlB4;
  BlinkM.TimerCompare -> MSP430TimerC.CompareB4;
}

