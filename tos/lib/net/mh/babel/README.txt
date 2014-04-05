README for Babel routing protocol
Author/Contact: Martin Cerveny

Description:

This library implements Babel routing protocol (see RFC6126).
It implements RouteSelect interface for Multihop forwarding engine.
It also disclosure useful "table" information in NeighborTable and RoutingTable.

Tools:

see example in apps/MHHello/*

Known bugs/limitations:

- beta stage
- now LocalIeeeEui64C needed + collided address changing (should be optional)
...
