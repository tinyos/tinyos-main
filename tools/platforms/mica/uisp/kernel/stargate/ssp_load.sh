#!/bin/sh
module="stargate_ssp"
device="ssp"

# invoke insmod with all arguments we got
# and use a pathname, as newer modutils don't look in . by default
/sbin/insmod -f ./stargate_ssp.o $* || exit 1

rm -f /dev/${device}[0-7]
mknod /dev/${device} c $major 0

chmod 644 /dev/${device}






