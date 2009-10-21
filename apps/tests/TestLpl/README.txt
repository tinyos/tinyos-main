README for TestLPL
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

A simple low-power-listening test app, which cycles through different
low-power-listening settings every ~32s, repeating every ~192s. 

This application currently runs on motes using the CC1000, CC2420 and
RF230 radios. To compile for motes with CC2420 or RF230 radios, you
must do:
  env CFLAGS="-DLOW_POWER_LISTENING" make <platform>

This application blinks LED 0 every time it sends a message, and toggles
LED 1 every time it receives a message. If this application is
working correctly (see caveat about timing below), you should see 
both nodes toggling LED 1.

Its low-power-listening settings are as follows (repeating every 256s):

0-32s:     receive: fully on
           send: every second, to fully on listener

32-64s:    receive: fully on
	   send: every second, to low-power-listeners with 100ms interval

64-96s:    receive: low-power-listening with 250ms interval
	   send: every second, to low-power-listeners with 250ms interval

96-128s:   receive: low-power-listening with 250ms interval
	   send: every second, to fully on listener

128-160s:  receive: low-power-listening with 10ms interval
	   send: every second, to low-power-listeners with 10ms interval

160-192s:  receive: low-power-listening with 2000ms interval
	   send: every 7 seconds, to low-power-listeners with 2000ms interval

Whether two motes running TestLPL can receive each others messages depends
on their current send and receive low-power-listening settings. If you reset
two such motes at the same time, they will be able to receive each other's
messages in the following intervals: 0-96s and 128-192s.

Tools:

None.

Known bugs/limitations:

None.

