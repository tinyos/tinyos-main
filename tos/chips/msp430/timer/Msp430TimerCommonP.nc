
module Msp430TimerCommonP @safe()
{
  provides interface Msp430TimerEvent as VectorTimerA0;
  provides interface Msp430TimerEvent as VectorTimerA1;
  provides interface Msp430TimerEvent as VectorTimerB0;
  provides interface Msp430TimerEvent as VectorTimerB1;
}
implementation
{
  TOSH_SIGNAL(TIMERA0_VECTOR) { signal VectorTimerA0.fired(); }
  TOSH_SIGNAL(TIMERA1_VECTOR) { signal VectorTimerA1.fired(); }
  TOSH_SIGNAL(TIMERB0_VECTOR) { signal VectorTimerB0.fired(); }
  TOSH_SIGNAL(TIMERB1_VECTOR) { signal VectorTimerB1.fired(); }
}

