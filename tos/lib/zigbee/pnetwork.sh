#! /bin/bash
# script to compile and install software in a network of telosb motes.
# Usage pnetwork_install.sh

# Program the PAN coordinator on /dev/ttyUSB0 with address 0 
./pmote.sh i c 0 0

# Program the Router on /dev/ttyUSB1, with address 1, depth 1 
# and to associate with the coordinator (0)
./pmote.sh i r 1 1 1 0

# Program 2 end devices on /dev/ttyUSB2 and /dev/ttyUSB3, with addresses 10 and 11, depth 2,
# to associate with the router (1) and at predefined positions (x,y)
./pmote.sh i e 2 10 2 1 120 150
./pmote.sh i e 3 11 2 1 173 116

