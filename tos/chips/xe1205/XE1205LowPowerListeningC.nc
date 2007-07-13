

configuration XE1205LowPowerListeningC {
    provides {
	interface SplitControl;
	interface Send;
	interface Receive;
	interface LowPowerListening;
	//	interface CsmaBackoff[am_id_t amId];
    }
}
implementation {
    components MainC,
	XE1205ActiveMessageC,
	XE1205LowPowerListeningP,
	/*XE1205CsmaP as*/ XE1205CsmaRadioC,
	RandomC;
    components new TimerMilliC() as SendTimeoutC;
    components new TimerMilliC() as OnTimerC;
    components new TimerMilliC() as OffTimerC;
    
    Send = XE1205LowPowerListeningP;
    Receive = XE1205LowPowerListeningP;
    SplitControl = XE1205LowPowerListeningP;
    LowPowerListening = XE1205LowPowerListeningP;
    //    CsmaBackoff = XE1205LowPowerListeningP;

    MainC.SoftwareInit -> XE1205LowPowerListeningP;
    
    //XE1205LowPowerListeningP.LowPowerListening -> XE1205CsmaRadioC;    
    XE1205LowPowerListeningP.SubControl -> XE1205CsmaRadioC;
    XE1205LowPowerListeningP.CsmaControl -> XE1205CsmaRadioC;
    //  XE1205LowPowerListeningP.SubBackoff -> XE1205CsmaRadioC;
    XE1205LowPowerListeningP.SubSend -> XE1205CsmaRadioC.Send;
    XE1205LowPowerListeningP.SubReceive -> XE1205CsmaRadioC.Receive;
    XE1205LowPowerListeningP.AMPacket -> XE1205ActiveMessageC;
    XE1205LowPowerListeningP.PacketAcknowledgements -> XE1205ActiveMessageC;// XE1205CsmaRadioC;
    XE1205LowPowerListeningP.SendTimeout -> SendTimeoutC;
    XE1205LowPowerListeningP.OnTimer -> OnTimerC;
    XE1205LowPowerListeningP.OffTimer -> OffTimerC;
    XE1205LowPowerListeningP.Random -> RandomC;
    XE1205LowPowerListeningP.LPLControl -> XE1205CsmaRadioC.LPLControl;

}
