README for Blink
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Blink is a simple application that blinks the 3 mote LEDs. It tests
that the boot sequence and millisecond timers are working properly.
The three LEDs blink at 1Hz, 2Hz, and 4Hz. Because each is driven by
an independent timer, visual inspection can determine whether there are
bugs in the timer system that are causing drift. Note that this
method is different than RadioCountToLeds, which fires a single timer
at a steady rate and uses the bottom three bits of a counter to display
on the LEDs.

This is a testing version of Blink.  It checks to make sure that localtime
doesn't go backward.  If it does a breakpoint is hit and it goes into an
infinte loop and the leds stop cycling.  We also grab the leds so they
can be looked at.

Tools: None

Known bugs/limitations: None.
