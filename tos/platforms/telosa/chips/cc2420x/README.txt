CC2420X is an alternative radio stack for the TI CC2420 radio, using the
rfxlink library (lib/rfxlink). The stack is IEEE802.15.4 compliant. All
rfxlink features are supported. See lib/rfxlink/README.txt for details.

The stack can be used with microsecond-precision timestamping, as well as
with 32khz timestamping. 

To use this stack with microsecond precision timestamping configuration,
compile the application with the cc2420x extra:

make telosb cc2420x

To use this stack with 32khz precision timestamping configuration, add
the following lines to the Makefile:

make telosb cc2420x_32khz

Remarks:
- This stack programs the msp430 clock subsystem differently than the
  default cc2420 stack. In particular, SMCLK is ticking at 4MHz, which
  allows for faster peripheral access.
- Microsecond precision timestamping requires that TimerB is set to
  SMCLK/4, therefore TimerA must be configured as the 32khz clock (ACLK).
  Since TimerA has only three compare registers, this limits the number
  of physical (that is, unvirtualized) 32kHz alarms in the system. (This
  is not an issue if 32khz timestamping is used).
- 32khz timestamping is not interoperable with other devices (e.g. iris).
