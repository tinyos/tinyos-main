README for TestNetwork
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

TestNetworkC exercises the basic networking layers, collection and
dissemination. The application samples DemoSensorC at a basic rate
and sends packets up a collection tree. The rate is configurable
through dissemination.

See TEP118: Dissemination, TEP 119: Collection, and TEP 123: The
Collection Tree Protocol for details.

There are scripts on net2 website to parse the debug messages sent by
the nodes.

To test, start with two motes with no program that transmits
packets. Example., erase the mote or install Blink. Program a mote with
node id 0. The mote will toggle led1 (green on TelosB) approximately
every 8s. Then program the second mote with id 1. Once programming is
complete, the mote with id 0 will toggle led1 twice every 8s. Each
toggle corresponds to the reception of collection message (once from
itself, and once from the mote with id 1).

Errors indications:

Motes 0 and 1 will set led0 (red on TelosB) if there are errors while
sending the packet.

Mote 0 will set led2 (blue on TelosB) if the gap in sequence number on
consecutive packet reception from node 1 is greater than 1. This is
expected to be a rare event while doing experiment on a desk.


Known bugs/limitations:

None.
