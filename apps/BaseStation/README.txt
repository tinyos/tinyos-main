README for BaseStation
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

BaseStation is an application that acts as a simple Active Message
bridge between the serial and radio links. It replaces the GenericBase
of TinyOS 1.0 and the TOSBase of TinyOS 1.1.

On the serial link, BaseStation sends and receives simple active
messages (not particular radio packets): on the radio link, it sends
radio active messages, whose format depends on the network stack being
used. BaseStation will copy its compiled-in group ID to messages
moving from the serial link to the radio, and will filter out incoming
radio messages that do not contain that group ID.

BaseStation includes queues in both directions, with a guarantee that
once a message enters a queue, it will eventually leave on the other
interface. The queues allow the BaseStation to handle load spikes more
gracefully.

BaseStation acknowledges a message arriving over the serial link only if
that message was successfully enqueued for delivery to the radio link.

The LEDS are programmed to toggle as follows:

RED Toggle         - Message bridged from serial to radio
GREEN Toggle       - Message bridged from radio to serial
YELLOW/BLUE Toggle - Dropped message due to queue overflow 
                     in either direction

Tools:

tools/java/net/tinyos/sf/SerialForwarder.  

See doc/serialcomm/index.html for more information using these tools.

Known bugs/limitations:

On CC2420 platforms, BaseStation can only overhear packets transmitted
to it or to the broadcast address. For these platforms (e.g., micaz,
telos, intel mote 2), you should use BaseStationCC2420.


