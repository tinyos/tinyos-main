README for SyncLog
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test 'sync' functionality in the LogStorageC
abstraction, using the log in linear mode. There must be a
volumes-<chip>.xml file in this directory describing a 64kB volume
named SYNCLOG for your flash chip.

A successful test will send serial messages (id 11) with increasing
sequence numbers (approximately 2 messages every 5 seconds) - the
easiest way to see these messages is to connect the mote with the
SyncLog code to your PC and run the java Listen tool:
  MOTECOM=serial@<your mote details> java net.tinyos.tools.Listen

This test is based on code and a bug report from Mayur Maheshwari
(mayur.maheshwari@gmail.com).

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.2 2007-07-11 20:36:07 idgay Exp $
