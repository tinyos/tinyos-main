README for TestClusterTree
Author/Contact: Jasper Buesch <buesch@tkn.tu-berlin.de>

-------------------------------------------------------------------------------

Description:

This application creates a multihop topology out of three nodes: a PAN
Coordinator, a "Router" (Coordinator and Device role) and a Device. The Router
associates to the PAN Coordinator and the Device associates to the Router, so
the topology is:

              PAN Coordinator <-> Router <-> Device

PAN Coordinator and Router send periodic beacons, but their active portions
are shifted in time (so they don't overlap, see detailed explanation below).
The Device can send packets only to the Router. And that's what is happening:
after the Router has associated and synchronized with the PAN Coordinator it
starts transmitting periodic beacons itself.  Once the Device receives these
beacon it associates and synchronizes to the Router. Then the device starts
sending periodic DATA packets to the Router (1 packet/s). Whenever the Router
receives a DATA packet from the device it forwards the packet to the PAN
Coordinator. A node toggles its LED2 (Telos: blue) every time a beacon is sent
or received and it toggles LED1 (Telos: green) every time a DATA frame is sent
or received.  Therefore, the Router's LEDs should to toggle twice as fast as
the LEDs of the other nodes. LEDs are toggling in unison / at the same time.


Criteria for a successful test:

Device and PAN Coordinator should toggle LED1 and LED2 with the same frequency.
The Router should toggle LED1 and LED2 with twice that frequency.  LEDs are not
toggled in unison.


-------------------------------------------------------------------------------

Superframe structure:

PAN Coordinator and Router send beacons with the same frequency. Each beacon is
followed by an active period (see IEEE 802.15.4-2006 Sect. 5.5.1). It is
important that the active periods of the PAN Coordinator and Router do not
overlap, i.e. we want a configuation like this:


  Superframe structure PAN coordinator:

  ||---------------------------|--------------------------------------------|
  ||    Active period          |             Inactive period                |
  ||---------------------------|--------------------------------------------|

  |<----- defined by SO ------>|


  Superframe structure Router:

  |----------------------------------------||---------------------------|---|
  |         Inactive period                ||      Active period        |   |
  |----------------------------------------||---------------------------|---|

                                           |<----- defined by SO ------>|

  |<- "StartTime" in MLME_START.request()->|

  |<---------------------------- defined by BO ----------------------------->|


So the parameters that influence a superframe structure are Beacon Order(BO)
and Superframe Order(SO) and the parameter that influences the time offset
between the active periods of the PAN Coordinator and Router is "StartTime" in
the MLME_START.request() interface (used only on the Router).

  => Formula to transform Beacon Order(BO) and Superframe Order(SO) values 
     into symbols and seconds (refer to section "7.5.1.1 Superframe structure"):
    
    - 0 ≤ BO ≤ 14; 0 ≤ SO ≤ 14
    - symbol-time in seconds        = 16 us (microseconds)
    - aBaseSlotDuration             = 60
    - aNumSuperframeSlots           = 16
    - aBaseSuperframeDuration       = aBaseSlotDuration * aNumSuperframeSlots
                                    = 960
    - Beaconintervall BI in symbols = aBaseSuperframeDuration * 2^BO
                                    = 960 * 2^BO
    - Beaconintervall BI in seconds = BI (in symbols) * 16 us

     Example:
       BO = 4
        BI in symbols = 960 symbols * 2^4 = 15360 symbols
        BI in seconds = 15360 symbols * 16us = 0.24576 seconds



  => The "StartTime" parameter in MLME_START.request()
 
     The "StartTime" time offset in the router is defined in symbols.
     The value has to be chosen so that the active portions of router and
     PAN coordinator are not overlapping (refer to the figure above).
     One can, for example, use the duration of the active portion of
     PAN coordinator as "StartTime" on the Router. 


-------------------------------------------------------------------------------

Tools: NONE

Usage: 

1. Install the PAN coordinator:

    $ cd pancoord; make <platform> install

2. Install the router node:

    $ cd router; make <platform> install

3. Install the device node:

    $ cd device; make <platform> install

You can change some of the configuration parameters in app_profile.h

-------------------------------------------------------------------------------

Known bugs/limitations:

- Many TinyOS 2 platforms do not have a clock that satisfies the
  precision/accuracy requirements of the IEEE 802.15.4 standard (e.g. 
  62.500 Hz, +-40 ppm in the 2.4 GHz band); in this case the MAC timing 
  is not standard compliant


