The implementation of the 12-bit ADC stack on the MSP430 is in compliance with
TEP 101 (tinyos-2.x/doc/txt/tep101.txt) and provides virtualized access to the
ADC12 by seven different components: AdcReadClientC, AdcReadNowClientC,
AdcReadStreamClientC, Msp430Adc12ClientC, Msp430Adc12ClientAutoDMAC,
Msp430Adc12ClientAutoRVGC and Msp430Adc12ClientAutoDMA_RVGC. A client
component may wire to any of these components and it SHOULD NOT wire to any
other components in 'tinyos-2.x/tos/chips/msp430/adc12'. This document
explains the difference between the seven components.


A platform-independent application (an application like 'Oscilloscope' that is
supposed to run on, for example, the 'telosb' and 'micaz' platform at the same
time) cannot wire to an MSP430-specific interface like Msp430Adc12SingleChannel
(there is no MSP430 on micaz).  Instead such an application may access the
MSP430 ADC through any of the three following components:

  * AdcReadClientC: to read single ADC values
  * AdcReadNowClientC: to read single ADC values asynchronously (fast)
  * AdcReadStreamClientC: to read multiple ADC values

These components are less efficient than the MSP430-specific ADC components
(described below), but they provide standard TinyOS interfaces for reading ADC
values. Thus, if a client component does not care so much about efficiency but
rather about portability it should wire to any of these components.


An application that is written for an MSP430-based platform like 'eyesIFX' or
'telosb' can access the ADC12 in a more efficient way to, for example, do
high-frequency sampling through the Msp430Adc12SingleChannel interface. On the
MSP430 two additional hardware modules may become relevant when the ADC12 is
used: the internal reference voltage generator and the DMA controller. The
voltage generator outputs stabilized voltage of 1.5 V or 2.5 V, which may be
used as reference voltage in the conversion process. Whether the internal
reference voltage generator should be enabled during the conversion is
platform-specific (e.g. the light sensor on the 'eyesIFX' requires a stable
reference voltage). When an application requires a stable reference voltage
during the sampling process it should wire to the Msp430Adc12ClientAutoRVGC
component. This assures that when the app is signalled the Resource.granted()
event the reference voltage generator outputs a stable voltage (the level is
defined in the configuration data supplied by the application). The DMA
controller can be used to efficiently copy conversion data from ADC data
registers to the application buffer. DMA is only present on MSP430x15x and
MSP430x16x devices. When an application wants to use the DMA it can wire to
the Msp430Adc12ClientAutoDMAC component and then conversion results are
transferred using DMA. Both, enabling the reference generator and using the
DMA, therefore happens transparent to the app. There are four possible
combinations reflected by the following components that an MSP430-based
application may wire to:

  * Msp430Adc12ClientC: no DMA, no automatic reference voltage
  * Msp430Adc12ClientAutoRVGC: automatic reference voltage, but no DMA
  * Msp430Adc12ClientAutoDMAC: DMA, but no automatic reference voltage
  * Msp430Adc12ClientAutoDMA_RVGC: DMA and automatic reference voltage

During a conversion the respective ADC port pin (ports 6.0 - 6.7) must be
configured such that the peripheral module function is selected and the port
pin is switched to input direction. By default, for every client this is done
**automatically** in the ADC stack (Msp430Adc12ImplP), i.e. just before the
conversion starts the respective pin is switched to peripheral module function
and input direction and immediately after the conversion has finished it is
switched to I/O function mode. To disable this feature please comment out the
"P6PIN_AUTO_CONFIGURE" macro in Msp430Adc12.h.

-----

$Date: 2006-11-07 19:30:57 $
@author: Jan Hauer <hauer@tkn.tu-berlin.de>

