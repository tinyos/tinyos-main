
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Test the effectiveness of the PacketLink layer

INSTALL
  Transmitter: id == 1, 2, 3, 4, or 5 (up to MAX_TRANSMITTERS)
  Receiver: id == 0, plugged into the computer

EXPECTATIONS
   Transmitter (ID not 0) -
     led1 toggling on every successfully delivered message
     led0 toggling on every unsuccessfully delivered message (and stay on
       until the next dropped packet)
   
   Receiver (ID 0) -
     Leds represent the binary count of sets of messages that were dropped.
     Ideally, if the transmitter and receiver are in range of each other, 
     the receiver's LEDs should never turn on.  You can pull the receiver
     out of range for up to two seconds before the transmission will fail.
     If you aren't convinced the receiver is doing anything because its 
     leds aren't flashing, just turn it off and watch the transmitter's
     reaction.


Tools:

  java TestPacketLink [-comm <packetsource>]

  If not specified, the <packetsource> defaults to sf@localhost:9001 or
  to your MOTECOM environment variable (if defined).

  This application will report dropped and duplicate packets as seen on
  the receiver.

Known bugs/limitations:

None.

$Id: README.txt,v 1.3 2008-07-16 18:09:49 idgay Exp $
