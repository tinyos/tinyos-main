README for LplBroadcastPeriodicDelivery
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Install the application to two nodes with the following ID's:
  Node 0 (Receiver node): id = 0
  Node 1 (Transmitter node): id = 1

Do this at compile time by adding the flag NODEID=<id>, thus:

make <platform> NODEID=<id> ...

This app sends a message from Transmitter node to 
AM_BROADCAST_ADDR and waits 1000 ms between each 
delivery so the Rx mote's radio shuts back off and 
has to redetect to receive the next
message.


EXPECTED OUTPUT
  Transmitter Node:
    * Toggles its led0 every second.
      - led0 ON indicates transmission, which lasts
        for a full second.

  Receiver Node:
     * led1 remains on (except at the beginning)
     * If led0 lights up after the beginning of the
       test, without resetting the transmitter node,
       there is a problem.  This means a duplicate
       message was received
     * led2 toggles once each for each transmission
       received.

Summary:  Receiver node's led2 should be toggling once
a second and led0 should never light up (except at the beginning).



Tools:

RadioCountMsg.java is a Java class representing the message that
this application sends.  RadioCountMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


$Id: README.txt,v 1.7 2010-01-06 18:57:20 ayer1 Exp $
