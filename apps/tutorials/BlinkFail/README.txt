README for Blink
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

BlinkFail is based on Blink (described below).  It is designed to
violate memory safety after a few seconds and is used as a
demonstration and sanity check for Safe TinyOS.  For more information
about Safe TinyOS see here:

  http://www.cs.utah.edu/~coop/safetinyos/

Blink is a simple application that blinks the 3 mote LEDs. It tests
that the boot sequence and millisecond timers are working properly.
The three LEDs blink at 1Hz, 2Hz, and 4Hz. Because each is driven by
an independent timer, visual inspection can determine whether there
are bugs in the timer system that are causing drift. Note that this
method is different than RadioCountToLeds, which fires a single timer
at a steady rate and uses the bottom three bits of a counter to
display on the LEDs.

Tools:

Known bugs/limitations:

None.


$Id: README.txt,v 1.2 2008-07-03 18:41:36 regehr Exp $
