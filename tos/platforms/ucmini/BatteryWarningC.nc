configuration BatteryWarningC{
	provides interface Init; //it's not nice to use init, since the module is split-phase, but the module does nothing if everything is OK, and turns off, if not
}
implementation{
	components BatterySwitchC, new VoltageC(), BatteryWarningP, LedsC, HplSerialAutoControlC, BusyWaitMicroC;
	Init = BatteryWarningP;
	BatteryWarningP.Voltage -> VoltageC;
	BatteryWarningP.Switch -> BatterySwitchC;
  BatteryWarningP.GeneralIO -> HplSerialAutoControlC;
	BatteryWarningP.Leds -> LedsC;
	BatteryWarningP.BusyWait -> BusyWaitMicroC;
}