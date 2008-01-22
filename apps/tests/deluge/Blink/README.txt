README for apps/tests/deluge/Blink
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This application serves two purposes. First, it contains two test cases 
for Deluge T2: testing base station functionality and network-wide 
reprogramming. Second, it is a sample application referenced in the 
Deluge T2 manual to illustrate some of the basics in reprogramming. 
These are done with the two burn scripts in the directory.

The "burn" script performs the following tasks (on the basestation 
only):
   1) Compile and load the program normally.
   2) Compile another version of blink that blinks differently.
   3) Upload the new blink to flash volume 0.
   4) Instruct the mote to reprogram with the new blink.

The "burn-net" script performs the following tasks:
   1) Compile and load the program normally on multiple motes. The last 
      mote is designated to be the basestation.
   2) Compile another version of blink that blinks differently.
   3) Upload the new blink to flash volume 0 on the base station.
   4) Instruct the base station to disseminate the new blink.
   5) Instruct the base station to reprogram the network with the new 
      image.

To help testing, "burn-net" script describes what the user should expect 
in each step.

Alternatively, you can reprogram the whole network (non-basestation 
motes) by first uploading the image to the base station. Then, tell the 
base station to disseminate the image. For example,

   tos-deluge /dev/ttyUSB0 telosb -dr 1

For a more detailed discussion on Deluge T2, please refer to the Deluge 
T2 manual.

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 manual is available under $TOS_DIR/doc/html/.
