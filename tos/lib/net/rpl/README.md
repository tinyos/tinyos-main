RPL Stack for TinyOS
====================

This is an implementation of RPL ([RFC6550][rfc]) for TinyOS. It is designed
to be used with BLIP, the IPv6 stack.


Usage
-----

To use with BLIP, in your application `configuration` add the following:

    #ifdef RPL_ROUTING
      components RPLRoutingC;
    #endif

Then in your application `Makefile` be sure to add:

    PFLAGS += -DRPL_ROUTING
    PFLAGS += -I$(TOSDIR)/lib/net/rpl


Options
-------

There are a couple `#defines` that may be useful.

- **RPL_STORING_MODE**: Tells the node to keep routing information in its local
memory. If this is not defined the root node will be responsible for keeping
all routing information.
- **RPL_OF_MRHOF**: Use the "Minimum Rank Objective Function with Hysteresis"
objective function for choosing the best routes instead of just expected
transmissions.
- **RPL_GLOBALADDR**: Use the node's global address when routing instead of its
link-local address.



[rfc]: http://tools.ietf.org/html/rfc6550
