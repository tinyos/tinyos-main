README for Log
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the LogStorageC abstraction, using the log in linear
mode. There must be a volumes-<chip>.xml file in this directory describing
a 256kB volume named LOGTEST for your flash chip.

The mote id is of the form T*100 + k, where k is a random seed and
T specifies the test to be performed:

T = 0: perform a full test
T = 1: erase the log
T = 2: read the log
T = 3: write some data to the log

The read test expects to see one or more consecutive results of the data
written by the write test (with the same seed). The last write data can be
partial.  So, for instance, you could run the test with mote id = 104, then
304 twice to erase the log and write 2 copies of the data sequence for k =
4, then run with mote id = 204 to test all these writes. Or you can just
run the test with mote id = 4 to do a complete test.

If the log fills up (which should take 4 or 5 write operations), the write 
will fail, but a subsequent read will succeed.

A successful test will turn on the LED 1. A failed test will turn on
the LED 0. LED 1 blinks during the steps of the full test. A serial
message whose last byte is 0x80 for success and all other values
indicate failure is also sent at the end of the test.

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.5 2007-07-09 20:45:54 idgay Exp $
