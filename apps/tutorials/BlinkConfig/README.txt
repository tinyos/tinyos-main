$Id: README.txt,v 1.6 2007-04-06 01:13:59 prabal Exp $: README.txt,v 1.5 2006/12/12 18:22:52 vlahan Exp $

README for Config
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

  Application to demonstrate the ConfigStorageC abstraction.  A timer
  period is read from flash, divided by two, and written back to
  flash.  An LED is toggled each time the timer fires.

  To use this application:

    (i)   Program a mote with this application (e.g. make telos install)
    (ii)  Wait until the red LED turns off (writing to flash is done)
    (iii) Power cycle the mote and wait until the red LED turns off.
    (iv)  Repeat step (iii) and notice that the blink rate of the blue 
          (yellow) LED doubles each time the mote is power cycled.  The 
          blink rate cycles through the following values: 1Hz, 2Hz, 4Hz, 
          and 8Hz.

  The first time this application is installed, the green LED will
  light up and remain on (indicating that the configuration storage
  volume did not have the expected version number).

  The red LED will remain lit during the flash write/commit operation.

  The blue (yellow) LED blinks at the period stored and read from flash.

  See Lesson 7 for details.

Tools:

Known bugs/limitations:

None.
