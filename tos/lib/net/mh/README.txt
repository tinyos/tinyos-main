README for Multihop forwarder
Author/Contact: Martin Cerveny

Description:

This library has the same structure and usage as ActiveMessage framework.
It implements network layer (L3 network header, addressing and packet forwarding) over ActiveMessage (L2 only).
The routing (L2 next hop destination decision) is externally implemented over RouteSelect interface.

Tools:

see example in apps/MHHello/*

Known bugs/limitations:

- beta stage
- broadcast not implemented
- TTL not implemented
- multihop ACK not implemented
...
