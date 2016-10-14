configuration Jn516DebugC {
	provides interface Jn516Debug;
}
implementation {
	components Jn516DebugP;
	Jn516Debug = Jn516DebugP;

	components MainC;
	Jn516DebugP.Boot -> MainC;
	
	components LedsC;
	Jn516DebugP.Leds -> LedsC;

	components PlatformSerialC;
	Jn516DebugP.UartControl -> PlatformSerialC;
	Jn516DebugP.UartByte -> PlatformSerialC;

	components Jn516PacketC;
	Jn516DebugP.Jn516PacketBody -> Jn516PacketC;
}
