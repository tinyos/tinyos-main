$Id: README.txt,v 1.7 2007-04-06 02:48:44 prabal Exp $

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

  The first two times this application is installed, the green LED
  will light up and remain on (the first time indicating that the
  storage volume is not valid and second time that the volume does not
  have the expected version number).

  The red LED will remain lit during the flash write/commit operation.

  The blue (yellow) LED blinks with the period stored and read from
  flash.

  See Lesson 7 for details.

Tools:

Known bugs/limitations:

None.
