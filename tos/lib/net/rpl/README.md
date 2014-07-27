RPL Stack for TinyOS
====================

This is an implementation of RPL ([RFC6550][rfc]) for TinyOS. It is designed
to be used with BLIP, the IPv6 stack.


Usage
-----

To use with BLIP, in your application `configuration` add the following:

    #if RPL_ROUTING
      components RPLRoutingC;
    #endif

In your application `Makefile` be sure to add:

    PFLAGS += -DRPL_ROUTING=1

Then when running `make` add the extra `rpl`:

    make <target> blip rpl


Options
-------

There are a couple `#defines` that may be useful.

- **RPL_STORING_MODE**: Tells the node to keep routing information in its local
memory. If this is not defined the root node will be responsible for keeping
all routing information.
- **RPL_OF_0**: Use the objective function 0 for choosing the best routes.
- **RPL_OF_MRHOF**: Use the "Minimum Rank Objective Function with Hysteresis"
objective function for choosing the best routes instead of just expected
transmissions.



[rfc]: http://tools.ietf.org/html/rfc6550
