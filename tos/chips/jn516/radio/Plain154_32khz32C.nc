configuration Plain154_32khz32C {
	provides {
		interface Plain154PhyTx<T32khz,uint32_t>;
		interface Plain154PhyRx<T32khz,uint32_t>;
		interface Plain154PhyOff;
		interface GetSet<uint8_t> as RadioChannel;
	}
}
implementation {
	components Plain154_32khz32P;

	Plain154PhyTx = Plain154_32khz32P;
	Plain154PhyRx = Plain154_32khz32P;
	Plain154PhyOff = Plain154_32khz32P;
	RadioChannel = Plain154_32khz32P;

	components Plain154PacketTransformP;
	Plain154_32khz32P.PacketTransform -> Plain154PacketTransformP;

	components new MuxAlarm32khz32C() as AlarmFrom; //virtualized 32khz alarm
	Plain154_32khz32P.Alarm -> AlarmFrom.Alarm;

  components MainC, Jn516HWDebugC;
  Jn516HWDebugC.Boot -> MainC.Boot;
}
