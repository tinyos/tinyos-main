
Install:
Compile and install this application to one mote. Leave the mote connected
to the computer.

Expectations:
Led1 will toggle as each message is transmitted.  Once a second, the mote
will send a packet through the serial port to the computer.  Run the
TxThroughput java application:

  Linux: java TxThroughput.class [-comm <packetsource>]
  Windows: java TxThroughput [-comm <packetsource>]

The TxThroughput Java application will display the number of packets per
second and the number of bytes sent in the payload per second:

[Packets/s]: 124;  [(Payload Bytes)/s]: 3472
[Packets/s]: 126;  [(Payload Bytes)/s]: 3528
[Packets/s]: 115;  [(Payload Bytes)/s]: 3220
[Packets/s]: 124;  [(Payload Bytes)/s]: 3472

