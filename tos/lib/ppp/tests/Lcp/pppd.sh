#!/bin/sh
pppd \
    debug \
    noccp \
    passive \
    noauth \
    10.0.0.1:10.0.0.2 \
    nodetach \
    /dev/ttyUSB0
