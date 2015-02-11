

configuration CC2520KeyC
{
	provides interface CC2520Key;
}

implementation
{
	components CC2520KeyP;
	CC2520Key	= CC2520KeyP;

	components new CC2520SpiC() as Spi;
	CC2520KeyP.Key	 	-> Spi.KEY;
	CC2520KeyP.TXNonce	-> Spi.TXNONCE;
	CC2520KeyP.SpiResource 	-> Spi.Resource;

	components ActiveMessageAddressC;
	CC2520KeyP.ActiveMessageAddress -> ActiveMessageAddressC;

	components MainC;
	components AlarmMultiplexC as Alarm;
  	MainC.SoftwareInit -> CC2520KeyP;
  	MainC.SoftwareInit -> Alarm;

	components HplCC2520PinsC as Pins;
	CC2520KeyP.CSN	-> Pins.CSN;

}
