
module Msp430TimerCommonP @safe()
{
  provides interface Msp430TimerEvent as VectorTimerA0;
  provides interface Msp430TimerEvent as VectorTimerA1;
  provides interface Msp430TimerEvent as VectorTimerB0;
  provides interface Msp430TimerEvent as VectorTimerB1;
}
implementation
{
  TOSH_SIGNAL(TIMERA0_VECTOR) { 
    #ifdef DXNRG
    dxnrg_on(DXNRG_IRQ); 
    #endif
    signal VectorTimerA0.fired(); 
    #ifdef DXNRG    
    dxnrg_off(DXNRG_IRQ); 
    #endif
  }
  
  TOSH_SIGNAL(TIMERA1_VECTOR) { 
    #ifdef DXNRG
    dxnrg_on(DXNRG_IRQ);   
    #endif
    signal VectorTimerA1.fired();
    #ifdef DXNRG
    dxnrg_off(DXNRG_IRQ);     
    #endif
  }
  
  TOSH_SIGNAL(TIMERB0_VECTOR) { 
    #ifdef DXNRG  
    dxnrg_on(DXNRG_IRQ); 
    #endif
    signal VectorTimerB0.fired();
    #ifdef DXNRG
    dxnrg_off(DXNRG_IRQ); 
    #endif
  }
  
  TOSH_SIGNAL(TIMERB1_VECTOR) { 
    #ifdef DXNRG  
    dxnrg_on(DXNRG_IRQ); 
    #endif
    signal VectorTimerB1.fired();
    #ifdef DXNRG    
    dxnrg_off(DXNRG_IRQ); 
    #endif
  }
}

