README for Block
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the BlockStorageC abstraction. There must be a
volumes-<chip>.xml file in this directory describing the a 256kB volume
named BLOCKTEST for your flash chip.

The mote id is of the form T*100 + k, where k is a random seed and
T specifies the test to be performed:

T = 0: perform a full test
T = 2: read a previously written block with the same seed
T = 3: write a block with the given seed

For example, install with an id of 310 to write some data to the flash,
then with an id of 210 to check that the data is correct. Or install
with an id of 10 to do a combined write+read test.

A successful test will blink the yellow led a few times, then turn on
the green led. A failed test will turn on the red led. A serial message
whose last byte is 0x80 for success and all other values indicate
failure is also sent at the end of the test.

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.3 2006-11-07 19:30:37 scipio Exp $
