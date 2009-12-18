README for TestSecurity

Author/Contact:
JeongGil Ko <jgko@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
Jong Hyun Lim <ljh@cs.jhu.edu>

Description:

Test the CC2420 hardware security support


Applications:

1. RadioCountToLeds1/ 

This application is a modification to the RadioCountToLeds/
application with CC2420 security features added to outgoing
packets. The packets are decrypted at the receiver node. 

> INSTALL

Compile one node with ID 1 as the transmitter and other nodes with any
node IDs to receive the decrypted packets

>EXPECTATIONS

LEDs on the receiver nodes will blink their LEDs sequentially like the
original RadioCountToLeds/ application. The LEDs on the transmitter
will stay off.


2. Basestation/

The BaseStation application with the security extensions

> INSTALL

Follow instructions on apps/BaseStation/README.txt

> EXPECTATIONS

Identical to the expectations in  apps/BaseStation/README.txt



Known bugs/limitations:

None.
