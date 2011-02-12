The implementation of the 12-bit ADC stack on the MSP430 is in compliance
with TEP 101 (tinyos-2.x/doc/txt/tep101.txt) and provides virtualized access
to the ADC12 by seven different components: AdcReadClientC, AdcReadNowClientC,
AdcReadStreamClientC, Msp430Adc12ClientC, Msp430Adc12ClientAutoDMAC,
Msp430Adc12ClientAutoRVGC and Msp430Adc12ClientAutoDMA_RVGC. A client
component may wire to any of these components and it SHOULD NOT wire to any
other components in 'tinyos-2.x/tos/chips/msp430/adc12'. This document
explains the difference between the seven components.


1. HIL
====================================================================


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


2. HAL
====================================================================

An application that is written for an MSP430-based platform like 'eyesIFX' or
'telosb' can access the ADC12 in a more efficient way via two interfaces: (1)
the Msp430Adc12SingleChannel allows to perform one or more ADC conversions on a
single channel with a specified sampling frequency and (2) the
Msp430Adc12MultiChannel allows to sample a group of up to 16 different ADC
channels.

On the MSP430 two additional hardware modules may play a role when the ADC12 is
used: the internal reference voltage generator and the DMA controller. 

The voltage generator outputs stabilized voltage of 1.5 V or 2.5 V, which may
be used as reference voltage in the conversion process. Whether the internal
reference voltage generator should be enabled during the conversion is
platform-specific (e.g. the light sensor on the 'eyesIFX' requires a stable
reference voltage). When an application requires a stable reference voltage
during the sampling process it should wire to the Msp430Adc12ClientAutoRVGC
component. This assures that when the app is signalled the Resource.granted()
event the reference voltage generator outputs a stable voltage (the level is
defined in the configuration data supplied by the application). There are two
more things to note: first, the generator is not switched off immediately, when
the client calls Resource.release(), but only after some pre-defined interval
(see Msp430RefVoltGenerator.h). This can avoid a power-up delay when multiple
clients are present. Second, one must not forget to wire the AdcConfigure
interface to the Msp430Adc12ClientAutoRVGC or Msp430Adc12ClientAutoDMA_RVGC
component in addition to configuring the ADC through the
Msp430Adc12SingleChannel interface (a nesC warning will be signalled).
  
The DMA controller can be used to copy conversion data from the ADC registers
to the application buffer. DMA is only present on MSP430x15x and MSP430x16x
devices. When an application wants to use the DMA it can wire to the
Msp430Adc12ClientAutoDMAC component and then conversion results are transferred
using DMA. Both, enabling the reference generator and using the DMA, therefore
happens transparent to the app. There are four possible combinations reflected
by the following components that an MSP430-based application may wire to:

  * Msp430Adc12ClientC: no DMA, no automatic reference voltage
  * Msp430Adc12ClientAutoRVGC: automatic reference voltage, but no DMA
  * Msp430Adc12ClientAutoDMAC: DMA, but no automatic reference voltage
  * Msp430Adc12ClientAutoDMA_RVGC: DMA and automatic reference voltage

Currently Msp430Adc12MultiChannel is only provided by the first two components.

I/O PINs
--------------------------------------------------------------------

During a conversion the respective ADC port pin (ports 6.0 - 6.7) must be
configured such that the peripheral module function is selected and the port
pin is switched to input direction. By default, for every client this is done
**automatically** in the ADC stack (Msp430Adc12ImplP), i.e. just before the
conversion starts the respective pin is switched to peripheral module function
and input direction and immediately after the conversion has finished it is
switched to I/O function mode. To disable this feature please comment out the
"ADC12_P6PIN_AUTO_CONFIGURE" macro in Msp430Adc12.h.


Configuration for single channel conversions
--------------------------------------------------------------------

The msp430adc12_channel_config_t struct holds all information needed to
configure the ADC12 for single channel conversions. The flags come from the
following MSP430 registers: ADC12CTL0, ADC12CTL1, ADC12MCTLx and TACTL and are
named according to the "MSP430x1xx Family User's Guide". Their meaning is as
follows:

  .inch: ADC12 input channel (ADC12MCTLx register). An (external) input
  channel maps to one of msp430's A0-A7 pins (see device specific data sheet).

  .sref: reference voltage (ADC12MCTLx register). If REFERENCE_VREFplus_AVss
  or REFERENCE_VREFplus_VREFnegterm is chosen AND the client wires to the
  Msp430Adc12ClientAutoRVGC or Msp430Adc12ClientAutoDMA_RVGC component then
  the reference voltage generator has automatically been enabled to the
  voltage level defined by the "ref2_5v" flag (see below) when the
  Resource.granted() event is signalled to the client. Otherwise this flag is
  ignored.
  
  .ref2_5v: Reference generator voltage level (ADC12CTL0 register). See
  "sref".
  
  .adc12ssel: ADC12 clock source select for the sample-hold-time (ADC12CTL1
  register). In combination the "adc12ssel", "adc12div" and "sht" define the
  sample-hold-time: "adc12ssel" defines the clock source, "adc12div" defines
  the ADC12 clock divider and "sht" define the time expressed in jiffies.
  (the sample-hold-time depends on the resistence of the attached sensor, and
  is calculated using to the formula in section 17.2.4 of the user guide)
  
  .adc12div: ADC12 clock divider (ADC12CTL1 register). See "adc12ssel".
  
  .sht: Sample-and-hold time (ADC12CTL1 register). See "adc12ssel".
  
  .sampcon_ssel: Clock source for the sampling period (TASSEL for TimerA).
  When an ADC client specifies a non-zero "jiffies" parameter (using the
  Msp430Adc12SingleChannel.configureX commands), the ADC
  implementation will automatically configure TimerA to be sourced from
  "sampcon_ssel" with an input divider of "sampcon_id". During the sampling
  process TimerA will be used to trigger a single
  (Msp430Adc12SingleChannel interface) or a sequence of (Msp430Adc12MultiChannel 
  interface) conversions every "jiffies" clock ticks.
  
  .sampcon_id: Input divider for "sampcon_ssel"  (IDx in TACTL register,
  TimerA). See "sampcon_ssel".


Example: Assuming that SMCLK runs at 1 MHz the following code snippet
performs 2000 ADC conversions on channel A2 with a sampling period of 4000 Hz.
The sampling period is defined by the combination of SAMPCON_SOURCE_SMCLK,
SAMPCON_CLOCK_DIV_1 and a "jiffies" parameter of (1000000 / 4000) = 250. 

 
   #define NUM_SAMPLES 2000
   uint16_t buffer[NUM_SAMPLES];
   
   const msp430adc12_channel_config_t config = {
    INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_NONE,
    SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
    SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 
   };
  
  event void Boot.booted()
  {
    call Resource.request();
  }
  
  event void Resource.granted()
  {
    error_t result;
    result = call SingleChannel.configureMultiple(&config, buffer, BUFFER_SIZE, 250);
    if (result == SUCCESS)
      call SingleChannel.getData();
  }

  async event uint16_t* SingleChannel.multipleDataReady(uint16_t *buf, uint16_t length)
  {
    // buffer contains conversion results
  }


3. Implementation
====================================================================

The ADC12 stack is located at tinyos-2.x/tos/chips/msp430/adc12. Sensor
wrappers for the msp430 internal sensors are in
tinyos-2.x/tos/chips/msp430/sensors, an HAL test app can be found in
tinyos-2.x/apps/tests/msp430/Adc12.

-----

$Date: 2008/04/07 09:41:55 $
@author: Jan Hauer <hauer@tkn.tu-berlin.de>

