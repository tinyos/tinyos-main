#include <Atm128Timer.h>

configuration AlarmCounterMilliP {
	provides interface Init;
	provides interface Alarm<TMilli, uint32_t> as AlarmMilli32;
	provides interface Counter<TMilli, uint32_t> as CounterMilli32;
}

implementation {
	components new Atm128AlarmAsyncC(TMilli, ATM128_CLK8_DIVIDE_32);

	Init = Atm128AlarmAsyncC;
	AlarmMilli32 = Atm128AlarmAsyncC;
	CounterMilli32 = Atm128AlarmAsyncC;
}

