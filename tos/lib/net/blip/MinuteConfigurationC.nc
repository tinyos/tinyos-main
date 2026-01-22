configuration MinuteConfigurationC {
provides interface MinuteTimer[uint8_t id];
}
implementation {
	components MinuteTimerP;

	#if defined(PLATFORM_TELOSB) || defined(PLATFORM_IWISE) || defined(PLATFORM_SMOTE)
 		components new AlarmMilli32C() as Alarm, new AlarmToTimerC(TMilli) as AlarmToTimer;
	#elif defined(PLATFORM_MICAZ)  || defined(PLATFORM_IRIS)
	 components AlarmCounterMilliP as Alarm, new AlarmToTimerC(TMilli) as AlarmToTimer;
	#endif
	components new VirtualizeTimerC(TMilli,uniqueCount("Minute"));
	MinuteTimer=MinuteTimerP;
	MinuteTimerP.Timer->VirtualizeTimerC;
	VirtualizeTimerC.TimerFrom -> AlarmToTimer;
	AlarmToTimer.Alarm -> Alarm;

}
