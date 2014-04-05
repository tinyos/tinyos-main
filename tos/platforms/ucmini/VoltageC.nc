generic configuration VoltageC(){
	provides interface Read<uint16_t>;
}
implementation{
	components VoltageArbiterP;
	Read = VoltageArbiterP.Read[unique("UcminiVoltage.read")];
}