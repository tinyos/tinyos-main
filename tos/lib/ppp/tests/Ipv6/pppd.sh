#!/bin/sh
pppd \
    debug \
    passive \
    noauth \
    nodetach \
    noccp \
    ipv6 ::23,::24 \
    noip \
    /dev/ttyUSB0
