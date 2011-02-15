Introduction to FragmentPoolC

This utility provides support for a memory pool that fragments a large block
into arbitrarily sized smaller blocks based on need.

The use case is buffer management for arbitrarily-sized messages, such as
HDLC frames received.  A client requests a block of memory, fills part of
it, then returns the remainder to the pool.  It may then request a new
block, while the newly received message is processed.  Ultimately, the
fragment is released back to the pool.  The largest available fragment is
returned for each request.

The size of the buffer and the number of fragments that can be
simultaneously supported are individually configurable for each pool.

There is no limit on the duration that a fragment may be held, nor any
assumption on the order in which fragments are released.  Requests will fail
only if the entire pool is in use.
