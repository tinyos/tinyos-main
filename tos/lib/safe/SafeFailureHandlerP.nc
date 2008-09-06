
#include "Timer.h"

module SafeFailureHandlerP {
  uses {
    interface Leds;
    interface BusyWait<TMicro, uint16_t>;
  }
}
implementation {

  #ifndef asmlinkage
    #define asmlinkage
  #endif

  #ifndef noreturn
    #define noreturn __attribute__((noreturn))
  #endif

  void delay (int len) 
  {
    volatile int x;
    for (x=0; x<len; x++) { 
      call BusyWait.wait(2000);
    }
  }

  void v_short_delay (void) { delay (10); }

  void short_delay (void) { delay (80); }

  void long_delay (void) { delay (800); }

  void flicker (void)
  {
    int i;
    for (i=0; i<20; i++) {
	delay (20);
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
	delay (20);
	call Leds.led0On();
	call Leds.led1On();
	call Leds.led2On();
    }
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
  }

  void roll (void)
  {
    int i;
    for (i=0; i<10; i++) {
	delay (30);
	call Leds.led0On();
	call Leds.led2Off();
	delay (30);
	call Leds.led1On();
	call Leds.led0Off();
	delay (30);
	call Leds.led2On();
	call Leds.led1Off();
    }
    call Leds.led2Off();
  }
	    
  void separator (void)
  {
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    short_delay ();
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2On();
    v_short_delay ();
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    short_delay ();
  }

  void display_b4 (int c) 
  {
    switch (c) {
    case 3:
      call Leds.led2On();
    case 2:
      call Leds.led1On();
    case 1:
      call Leds.led0On();
    case 0:
      long_delay ();
      break;
    default:
      flicker ();
    }
    separator ();
  }

  void display_int (const unsigned int x)
  {
    int i = 14;
    do {
      display_b4 (0x3 & (x >> i));
      i -= 2;
    } while (i >= 0);
  }

  void display_int_flid (const unsigned int x)
  {
    roll ();
    display_int (x);
    roll ();
  }

  asmlinkage noreturn 
  void deputy_fail_noreturn_fast (int flid) @C() @spontaneous()
  {
    atomic {
      while(1) {
        display_int_flid(flid);
      }
    }
  }

  asmlinkage 
  void deputy_fail_mayreturn(int flid) @C() @spontaneous()
  {
    deputy_fail_noreturn_fast(flid);
  }

  asmlinkage noreturn 
  void deputy_fail_noreturn(int flid) @C() @spontaneous()
  {
    deputy_fail_noreturn_fast(flid);
  }
}
