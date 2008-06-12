
module Msp430TimerCommonP
{
  provides interface Msp430TimerEvent as VectorTimerA0;
  provides interface Msp430TimerEvent as VectorTimerA1;
  provides interface Msp430TimerEvent as VectorTimerB0;
  provides interface Msp430TimerEvent as VectorTimerB1;
  uses interface PlatformInterrupt;
}
implementation
{
  TOSH_SIGNAL(TIMERA0_VECTOR) { 
    signal VectorTimerA0.fired(); 
    call PlatformInterrupt.postAmble();
  }
  TOSH_SIGNAL(TIMERA1_VECTOR) { 
    signal VectorTimerA1.fired();
    call PlatformInterrupt.postAmble();
  }
  TOSH_SIGNAL(TIMERB0_VECTOR) { 
    signal VectorTimerB0.fired();
    call PlatformInterrupt.postAmble();
  }
  TOSH_SIGNAL(TIMERB1_VECTOR) { 
    signal VectorTimerB1.fired();
    call PlatformInterrupt.postAmble();
  }
}

