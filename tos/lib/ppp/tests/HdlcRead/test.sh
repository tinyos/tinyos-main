#!/bin/sh
#
# Standard test configuration and loop

loopcond=true
breakloop () {
  loopcond=false
}

trap breakloop 1 2

cat <<EOText
At the "Reading boot status" prompt, reset the board.  Inspect each
triplet to verify that the octet sequence in the test is echoed back
by the application.

Initiating loop test now...
EOText

while ${loopcond} ; do
  python gendata.py
done
