configuration BatterySwitchC{
	provides interface Read<uint8_t>;
}
implementation{
	components BatterySwitchP, AtmegaGeneralIOC, new TimerMilliC();
	Read = BatterySwitchP;
	BatterySwitchP.GeneralIO -> AtmegaGeneralIOC.PortD5;
	BatterySwitchP.Timer -> TimerMilliC;
}