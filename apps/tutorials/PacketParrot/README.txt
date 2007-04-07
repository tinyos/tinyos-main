$Id: README.txt,v 1.1 2007-04-07 21:53:25 prabal Exp $

README for PacketParrot

Author/Contact:

  tinyos-help@millennium.berkeley.edu

Description:

  PacketParrot demonstrates use of LogWrite and LogRead abstractions.
  A node writes received packets to a circular log and retransmits the
  logged packets (or at least the part of the packets above the AM
  layer) when power cycled.

  The application logs packets it receives from the radio to flash.
  On a subsequent power cycle, the application transmits logged
  packets, erases the log, and then continues to log packets again.
  The red LED is on when the log is being erased.  The blue (yellow)
  LED turns on when a packets is received and turns off when a packet 
  has been logged.  The blue (yellow) LED remains on when packets are 
  being received but are not logged (because the log is being erased).  
  The green LED flickers rapidly after a power cycle when logged 
  packets are transmitted.

  To use this application:

  (i)   Program one node (the "parrot") with this application using 
        the typical command (e.g. make telosb install)
  (ii)  Program a second node with the BlinkToRadio application.
  (iii) Turn the parrot node on.  The red LED will turn on briefly, 
        indicating that the flash volume is being erased.
  (iv)  Turn the second node on.  Nothing should happen on the second 
        node but the blue (yellow) LED on the parrot node should start
        to blink, indicating it is receiving packets and logging them 
        to flash.
  (v)   After a few tens of seconds, focus you attention on the second 
        node's LEDs and then power cycle the parrot node.  The LEDs on 
        the second node should rapidly flash as if they were displaying 
        the three low-order bits of a counter.  At the same time, the 
        green LED on the parrot node should flicker rapidly, in unison 
        with the LEDs on the second node, indicating that packets are 
        being transmitted.
  (vi)  Repeat step (v) a few times and notice that the parrot's blue 
        (yellow) LED turns on and doesn't turn off until just a bit 
        after the red LED, indicating that one or more packets were 
        received (the LED turned on) but these packets were not logged 
        (since the LED does not turn off) because the log is being 
        erased.

Tools:

  None

Known bugs/limitations:

  Only works on motes with the CC2420 radio.  Known to work with
  TelosB and Tmote nodes but currently flaky on the MicaZ nodes.
