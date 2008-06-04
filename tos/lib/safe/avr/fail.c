#undef SAFE_TINYOS

#include <stdint.h>
#include <avr/io.h>

// #define SIMPLE_FAIL

#ifndef SIMPLE_FAIL

static void led_off_0 (void) 
{ 
  *(volatile unsigned char *)59U |= 1 << 0;
}

static void led_off_1 (void)  { 
  *(volatile unsigned char *)59U |= 1 << 1;
}

static void led_off_2 (void)  {
  *(volatile unsigned char *)59U |= 1 << 2;
}

static void led_on_0 (void) { 
  *(volatile unsigned char *)59U &= ~(1 << 0);
}

static void led_on_1 (void) { 
  *(volatile unsigned char *)59U &= ~(1 << 1);
}

static void led_on_2 (void) { 
  *(volatile unsigned char *)59U &= ~(1 << 2);
}

static void delay (int len) 
{
  volatile int x, y;
  for (x=0; x<len; x++) { 
    for (y=0; y<1000; y++) { }
  }
}

static void v_short_delay (void) { delay (10); }

static void short_delay (void) { delay (80); }

static void long_delay (void) { delay (800); }

static void flicker (void)
{
    int i;
    for (i=0; i<20; i++) {
	delay (20);
	led_off_0 ();
	led_off_1 ();
	led_off_2 ();
	delay (20);
	led_on_0 ();
	led_on_1 ();
	led_on_2 ();
    }
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
}

static void roll (void)
{
    int i;
    for (i=0; i<10; i++) {
	delay (30);
	led_on_0 ();
	led_off_2 ();
	delay (30);
	led_on_1 ();
	led_off_0 ();
	delay (30);
	led_on_2 ();
	led_off_1 ();
    }
    led_off_2 ();
}
	    
static void separator (void)
{
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
    short_delay ();
    led_on_0 ();
    led_on_1 ();
    led_on_2 ();
    v_short_delay ();
    led_off_0 ();
    led_off_1 ();
    led_off_2 ();
    short_delay ();
}

static void display_b4 (int c) 
{
  switch (c) {
  case 3:
    led_on_2 ();
  case 2:
    led_on_1 ();
  case 1:
    led_on_0 ();
  case 0:
    long_delay ();
    break;
  default:
    flicker ();
  }
  separator ();
}

static void display_int (const unsigned int x)
{
  int i = 14;
  do {
    display_b4 (0x3 & (x >> i));
    i -= 2;
  } while (i >= 0);
}

static void display_int_flid (const unsigned int x)
{
  roll ();
  display_int (x);
  roll ();
}

#endif // ndef SIMPLE_FAIL

static inline void load_to_z_and_break (int value)
{
  asm volatile ("movw %0, %1" "\n\t"
		"break"       "\n\t"
		: "=z"(value)  : "r" (value));
}

void deputy_fail_noreturn_fast (int flid)
{
  asm volatile ("cli");
  load_to_z_and_break (flid);
  PORTA |= 7;

#ifdef SIMPLE_FAIL

  while (1) {
    int i;
    PORTA ^= 7;
    for (i = 0; i < 10; i++) {
      uint16_t dt = 50000;
      /* loop takes 8 cycles. this is 1uS if running on an internal 8MHz
	 clock, and 1.09uS if running on the external crystal. */
      asm volatile (
		    "1:	sbiw	%0,1\n"
		    "	adiw	%0,1\n"
		    "	sbiw	%0,1\n"
		    "	brne	1b" : "+w" (dt));
    }
  }

#else

  while (1) {
    display_int_flid (flid);
  }

#endif

}

void deputy_fail_mayreturn(int flid)
{
    deputy_fail_noreturn_fast(flid);
}

void deputy_fail_noreturn(int flid)
{
    deputy_fail_noreturn_fast(flid);
}
