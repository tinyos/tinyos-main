README for TestMultihopLqi
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

TestMultihopLqi is a hacked-up version of MultihopOscilloscope whose purpose
is to test the LQI code in lib/net/lqi. It achieves this by creating a 
CC2420ActiveMessageC component that generates synthetic LQI values. These
values have no resemblance to those found in the real world, and so are of
no use whatsoever when evaluating the effectiveness of a protocol that uses
them. They can be, however, useful for testing code, which is exactly
what this application does.

Known bugs/limitations:

This application is solely intended as a mechanism to test code paths
in lib/net/lqi. It is therefore of no predictive or quantitative value.

Notes:

TestMultihopLqi configures a mote whose TOS_NODE_ID modulo 500 is zero 
to be a collection root. The TOSSIM script "script.py" is a sample
driver program.

