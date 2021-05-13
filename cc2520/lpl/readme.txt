
ARCHITECTURE
=======================================================
The default LPL implementation uses a packet train with acknowledgements
enabled, shortened backoffs, and a spinning energy checking loop.

The default strategy can be improved by implementing a different architecture.
Right now the architecture looks like this:


  +----------------------------------+
  |           DefaultLplP            | -> To lower level Send
  | Responsible for retransmissions  | -> To lower level SplitControl
  | and turning the radio off when   | <- From lower level Receive
  | done, or on when starting to     |
  | transmit                         |
  +----------------------------------+
  |           PowerCycleP            |
  | Responsible for performing       | -> To lower level SplitControl
  | receive checks and leaving the   |
  | radio on                         |
  +----------------------------------+
  
I think the architecture should be changed.  If you're interested in doing work 
in this area, there's lots of development and research to be done.

First, take a look at tinyos-2.x-contrib/wustl/upma.  The architecture of the
CC2420 stack there is implemented to define a low-level abstraction layer
which separates radio-specific functionality from radio-independent
functionality.  This is nice.  By providing certain interfaces from the 
radio-dependant functionality, it makes it easier to maintain MAC layer 
stuff independent of the radio.  And that includes LPL.

One of the things that radio stack uses is an Alarm instead of a spinning
task/while loop.  Whereas the implementation here uses a static number of 
loops to detect if energy is on the channel, we would be better able
to achieve the smallest radio asynchronous receive check on-time by using an 
alarm.  After all, the radio only has to be on to span the quiet gaps in a 
transmitter's transmission, and we know approximately the duration of those
quiet gaps based on the backoff period, which the stack defines.

I recommend we redo some of the LPL architecture to look more like this:

  +----------------------------------+
  |          DefaultLplP             |
  | Responsible for retransmissions  |
  +----------------------------------+
           |   |   |       (Send, Receive, SplitControl goes through PowerCycle)
  +----------------------------------+
  |          PowerCycleP             |
  | Responsible for managing radio   | -> To lower level Send
  | on/off power, and telling        | -> To lower level SplitControl
  | PacketDetectP when to start/stop | <- From lower level Receive
  | its job                          |
  +----------------------------------+
  |         PacketDetectP            |
  | Responsible for detecting        | <- EnergyIndicator
  | energy, bytes, and/or packets.   | <- ByteIndicator
  | Notify PowerCycle when packets   | <- PacketIndicator
  | are detected                     |
  +----------------------------------+
  
This is pretty radio independent.

OTHER LOW POWER LISTENING STRATEGIES
=============================================================
Other low power listening layers can be implemented as well:
  * Continuous modulation / No Acknowledgements:
     > Allows the receiver to achieve the lowest possible receive check
       on time.  It's shown to be several times more efficient on the receive 
       check than the default.  This is a radio-dependent LPL strategy
       and the CC2420 can acheive it by putting some transmit register into
       test mode where it continually retransmits the contents of the TXFIFO.
       The CRC of the packet must be uploaded into the TXFIFO because it won't
       be calculated by the CC2420.  Not sure if the preamble and sync bytes
       need to be uploaded as well.  The transmitter takes a hit because it
       cannot receive acks in the middle of its packet train.   But since
       the receiver's energy consumption is so low, it's possible to increase
       the number of receive checks in order to lower the duration of the 
       transmission.
     > This strategy would be a good match for networks that must get data
       through quickly when there is data, but doesn't see too many
       transmissions in any given geographical area of the network.  Also
       a good strategy where your transmitters have more power.
       
  * 802.15.4/ZigBee End Node:
     > Queue up packets to Send to a particular destination until that node 
       checks in at some random time.  Use fields in the ack frame to let the 
       node know that packets are available.  Good match for networks where one 
       node has access to line power and other nodes are on batteries.
       
   * Low throughput acknowledgement LPL:
     > Just like the default, only it uses the ByteIndicator to turn off
       the radio as soon as it stops receiving bytes and no packet was
       received.  Able to get a much shorter receive check at the expense
       of decreased probability that you'll receive messages in a congested
       network.
       
