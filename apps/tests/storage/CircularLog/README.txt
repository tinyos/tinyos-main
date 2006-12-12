README for CircularLog
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the LogStorageC abstraction, using the log in circular
mode. There must be a volumes-<chip>.xml file in this directory describing
the a 256kB volume named LOGTEST for your flash chip.

The mote id is of the form T*100 + k, where k is a random seed and
T specifies the test to be performed:

T = 0: perform a full test
T = 1: erase the log
T = 2: read the log
T = 3: write some data to the log

The write test writes a random sequence of 4095 32-byte records chosen from
a set of 16 possible records. The read test checks that the log contains
that all records in the log are one of the 16 possible records. The valid
records depend on the seed. Running 2 write tests will fill the log, and
the third one will wrap around. So for instance, you could run the test
with id = 117 (erase), then 317 three times (fill the log and wrap around),
then 217 to check that the log is valid. Or just run it with id = 17
to perform a full test.

A successful test will turn on the green led. A failed test will turn on
the red led. The yellow led is turned on after erase is complete. A
serial message whose last byte is 0x80 for success and all other values
indicate failure is also sent at the end of the test.

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.4 2006-12-12 18:22:52 vlahan Exp $
