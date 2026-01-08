

configuration SSLC_DA
{

	provides interface SplitControl;


}

implementation
{
	components SSLP_DA;
	SplitControl = SSLP_DA;

	components IPStackC;
	SSLP_DA.RadioControl->IPStackC;

	components new TimerMilliC() as DATimer;
	SSLP_DA.DATimer -> DATimer;

	components new TimerMilliC() as DeleteTimer;
	SSLP_DA.DeleteTimer -> DeleteTimer;

	components new UdpSocketC() as Send,
	new UdpSocketC() as Receive;

	SSLP_DA.UDPSend -> Send;
	SSLP_DA.UDPReceive  -> Receive;

	components IPAddressC;
	SSLP_DA.IPAddress->IPAddressC;

	components LedsC;
	SSLP_DA.Leds -> LedsC;

 // #ifdef RPL_ROUTING
	 // components RPLRoutingC;
	//#endif
	

#ifdef IN6_PREFIX
 components StaticIPAddressTosIdC;
#endif





}
