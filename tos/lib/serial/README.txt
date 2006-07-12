The purpose of this UART stack is to allow arbitary packet
formats to be encapsulated within a UART frame. The basic 
problem is that TinyOS needs to support two mote classes. 
The first are mote end points, which receive and process packets, 
possibly moving data between link layers. The second are mote
bridges, which transparently forward data packets between media.

The first class is simple: the UART can support its own active
messages implementation, which is platform independent.
An application that wants to send data to a mote generates a
AM formatted for the UART and sends it to the mote over the 
serial connection. The UART implementation then provides standard
2.x accessors for the AM fields, such as destination. In this
case, the UART is another packet format written into message_t.

The second class is more difficult. The goal for this class is
that you can communicate with a TinyOS network through data link
layer packets, rather than at AM layer packets. So, for example,
you can snoop on all of the 802.15.4 packets being sent and see
all of the 802.15.4 specific headers. Or, you can send an 802.15.4
packet to a mote over a serial port and it will just forward it
over the radio. This functionality allows a PC to directly
interact with the network, which has been shown to be an
important requirement, especially when monitoring or testing
deployed networks.

The problem is more difficult due to how message_t works. As all 
data link layers are justified on the data payload of the C
structure, data link headers can start at offsets within the structure
(as packets must be contiguous in memory). Therefore, to be
able to read in an 802.15.4 packet over the serial port, the UART
subsystem needs to know *where* in message_t the packet begins.
Assuming what comes in over the serial port is correctly formatted,
then if it knows the offset, the UART stack can just spool the
bytes directly into the message_t at that offset.

The send direction has a similar issue: the UART layer has to know
where in the message_t the actual packet begins, and how long the
entire packet is.

Given that it might need to receive a wide range of packet formats
encapsulated in a UART frame, the UART frame needs an identifier
to dispatch on what type of data is within the frame. The basic
case -- a platform independent AM packet -- is just one of these
identifiers. This means that the UART provides a parameterized
send and receive interface, where the parameter is the type of
data encapsulated in the frame. The receive and send interfaces 
need to be able to map one of these identifiers to a message_t offset
as well as calculate the packet length in terms of a data link
layer (e.g., if the length only pertains to the data payload of
the encapsulated packet, then the UART system needs to subtract
the header and footer length from the frame length).

The solution is that every encapsulated packet type has a component
that implements the SerialPacketInfo interface, which provides
three commands.

offset(), which returns the offset at which a packet begins in the message_t
dataLinkLen(), which returns the length of a data link packet given a 
data payload length
upperLen(), which returns the length of a payload given a packet
length 





The offset of a given data link packet in a message_t is known
at compile time: there is no need to store it in RAM. Therefore,
whe




