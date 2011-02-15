#!/bin/sh
#
# Standard test configuration and loop

loopcond=true
breakloop () {
  loopcond=false
}

trap breakloop 1 2

cat <<EOText
At the "Reading boot status" prompt, reset the board.  Multiple frames
will be exchanged; check that the summary indicates that all were
received correctly.

Initiating loop test now...
EOText

while ${loopcond} ; do
  python gendata.py
done
