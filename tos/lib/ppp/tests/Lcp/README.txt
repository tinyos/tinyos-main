Lcp tests the basic link control protocol negotiation.

This test is really an environment for manual experimentation.  For a basic
check run these commands:

make surf osian dco,16 install \
&& python pppd.py

Ideally, a series of exchanges will be printed culminating in something
like:

1349 PPP INFO Link up
STX: ff7d23c0217d227d237d207d307d217d247d257d207d227d267d207d207d207d207d287d2239bc7e
UP AND RUNNING

You can also verify your vendor PPP daemon against this application, though
no network control protocols are linked in so the comnnection may not form.

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

A successful execution in that case might produce:

sent [LCP ConfReq id=0x1 <asyncmap 0x0> <magic 0x3db44edf> <pcomp> <accomp>]
rcvd [LCP ConfReq id=0x4 <mru 1280> <asyncmap 0x0> <accomp>]
sent [LCP ConfAck id=0x4 <mru 1280> <asyncmap 0x0> <accomp>]
rcvd [LCP ConfRej id=0x1 <magic 0x3db44edf> <pcomp>]
sent [LCP ConfReq id=0x2 <asyncmap 0x0> <accomp>]
rcvd [LCP ConfAck id=0x2 <asyncmap 0x0> <accomp>]
sent [IPV6CP ConfReq id=0x1 <addr fe80::fd41:4242:0e88:0002>]
rcvd [LCP ProtRej id=0x0 80 57 01 01 00 0e 01 0a fd 41 42 42 0e 88 00 02]
Protocol-Reject for 'IPv6 Control Protocol' (0x8057) received

