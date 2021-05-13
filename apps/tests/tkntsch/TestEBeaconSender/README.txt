README for TestEbSender
Author/Contact: buesch@tkn.tu-berlin.de

Description:

This applications sends enhanced beacons in IEEE 802.15.4e format
with payload information elements in random order.
This can be used to verify the correctness of an IE parsing
algorithm at another receiver.


Install procedure in the JN516:

make nxp_jn516_{carrier,dongle} install port,/dev/ttyUSBx [TOS_CHANNEL=<CHANNEL>]


Criteria for a successful test:

---

Known bugs/limitations:

---

$Id: README.txt,v 1.1 2015/07/03 14:18:00 jasperbuesch Exp $
