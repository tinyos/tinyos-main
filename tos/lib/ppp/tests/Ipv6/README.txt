Basic demonstration of a PPP application negotiating support for RFC5072
IPv6 over PPP.

The red LED indicates that the PPP link is down; the green LED indicates
that it is up.  Upon receipt of an IPv6 packet, the blue LED toggles, and
the number of octets in the packet is printed over the PPP link.

Use a standard Linux PPP daemon, or the osianpppd script, to form the
connection.

pppd \
    115200 \
    debug \
    passive \
    noauth \
    nodetach \
    noccp \
    ipv6 ::23,::24 \
    noip \
    /dev/ttyUSB0

You can only see the printf data if your ppp daemon has the necessary patch
to add that protocol.  Ping the remote interface to verify packets are being
received over the NCP:

ping6 fe80::24%ppp0

For a basic check using PPP4Py, run these commands:

make surf osian dco,16 install \
&& python pppd.py

