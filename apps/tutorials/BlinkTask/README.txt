$Id: README.txt,v 1.3 2006-11-07 19:30:37 scipio Exp $

README for BlinkTask

Author/Contact:

  tinyos-help@millennium.berkeley.edu

Description:

  The BlinkTask application: a simple example of how to post a task
  in TinyOS. A periodic timer is set to fire every 
  second. The Timer.fired() event posts a task to toggle the LEDs
  rather than toggling the LEDs directly. 

Tools:

  None

Known bugs/limitations:

  None.