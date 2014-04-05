configuration VoltageArbiterP{
	provides interface Read<uint16_t>[uint8_t id];
}
implementation{
	components SingleVoltageC, new FcfsArbiterC("UcminiVoltage.read"), new MultiplexedReadC(uint16_t);
	Read=MultiplexedReadC;
	MultiplexedReadC.Service -> SingleVoltageC;
	MultiplexedReadC.Resource -> FcfsArbiterC;
	MultiplexedReadC.ArbiterInfo -> FcfsArbiterC;
}