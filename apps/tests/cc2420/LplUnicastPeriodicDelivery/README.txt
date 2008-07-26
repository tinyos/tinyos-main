README for LplUnicastPeriodicDelivery
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Install the application to two nodes with the following ID's:
  Node 0 (Receiver node): id = 0
  Node 1 (Transmitter node): id = 1 (or.. id > 0)


This app sends a message from Transmitter node to 
the recevier node and waits 1000 ms between each 
delivery so the Rx mote's radio shuts back off and 
has to redetect to receive the next message.


EXPECTED OUTPUT
  Transmitter Node:
    * Toggles its led0 every second.
      - led0 ON indicates transmission, which lasts
        for much shorter than a second.  When the
        receiver performs its receive check, the transmitter
        stops delivering the message.

  Receiver Node:
     * led1 toggles once a second, indicating reception.


Tools:

None.

Known bugs/limitations:

None.


$Id: README.txt,v 1.4 2008-07-26 02:32:44 klueska Exp $
