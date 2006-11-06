README for MViz
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

MViz is a sample application for the MViz network visualization tool. The MViz
application is a multihop collection network. Nodes whose (ID % 500) == 0 are
collection roots. The application samples a platform's DemoSensorC and routes
those values to the collection roots. The roots send the packets to the serial
port, which the MViz java application then visualizes.

To run this application, install the TinyOS application on several nodes, one
of whom is a root. Then run the tos-mviz script with MVizMsg as a parameter:

tos-mviz [-comm source] MVizMsg

This will cause the MViz java tool to parse the fields of MVizMsg and make
them displayable. As nodes send readings to the base station, they will be
displayed in the GUI. 

By default, the TinyOS program uses an artificial demonstration sensor that
just generates a sine wave (MVizSensorC). To change the sensor that
the MViz application uses, change the wiring in MVizAppC to your sensor
of choice.

Tools:

The Java application lives in support/sdk/java/net/tinyos/mviz. It is
invoked by the tos-mviz script, which is part of a TinyOS tools  distribution.
The top-level Java class is net.tinyos.mviz.DDocument. To display a mote image,
the tool looks for a mote.gif in either the local directory (default) or a 
directory specified with the -dir parameter.

Known bugs/limitations:

Under Ubuntu Linux, the MViz Java visualization can be painfully slow.

Notes:

MViz configures a mote whose TOS_NODE_ID modulo 500 is zero to be a
collection root. 
