README for apps/tests/deluge/Blink
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This application serves two purposes. First, it contains two test cases 
for Deluge T2: testing base station functionality and network-wide 
reprogramming. Second, it is a sample application referenced in the 
Deluge T2 wiki page to illustrate some of the basics in reprogramming. 
These are done with the two burn scripts in the directory.

The "burn" script performs the following tasks (on the basestation 
only):
   1) Compile and load the program normally. After this step the mote
      will blink led 0.
   2) Compile another version of blink that blinks led 2.
   3) Upload the new blink to flash volume 1.
   4) Instruct the mote to reprogram with the new blink.

If all the steps are executed properly the mote end up blinking the
led 2.

The "burn-net" script performs the following tasks:
   1) Compile and load the program normally on multiple motes. The last 
      mote is designated to be the basestation.
   2) Compile another version of blink that blinks led 2.
   3) Upload the new blink to flash volume 1 on the base station.
   4) Give the command to base station to disseminate-and-reprogram.

To help testing, "burn-net" script describes what the user should expect 
in each step. At the end of all the steps the base station should
blink led 0 and all the rest of the motes should blink led 2.

For a more detailed discussion on Deluge T2, please refer to the Deluge 
T2 wiki page.

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 wiki page from http://docs.tinyos.net/
