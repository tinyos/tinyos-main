configuration HilTimerMilliC {
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[ uint8_t num ];
  provides interface LocalTime<TMilli>;
}

implementation {
	enum {
		TIMER_COUNT = uniqueCount(UQ_TIMER_MILLI)
	};

	components AlarmCounterMilliP, new AlarmToTimerC(TMilli),
	new VirtualizeTimerC(TMilli, TIMER_COUNT),
	new CounterToLocalTimeC(TMilli);

	Init = AlarmCounterMilliP;

	TimerMilli = VirtualizeTimerC;
	VirtualizeTimerC.TimerFrom -> AlarmToTimerC;
	AlarmToTimerC.Alarm -> AlarmCounterMilliP;

	LocalTime = CounterToLocalTimeC;
	CounterToLocalTimeC.Counter -> AlarmCounterMilliP;
}

