This directory contains "TKN15.4", a platform-independent IEEE 802.15.4-2006
MAC implementation. The code is under active development and most of the
functionality described in the standard is implemented and tested.  The MAC
itself is platform-independent, but it requires (1) a suitable radio driver,
(2) Alarms/Timers with symbol precision and (3) some "platform glue" code
(defining guard times, etc.). Currently the only supported platforms are TelosB
and micaZ (note: because they do not have a clock that satisfies the
precision/accuracy requirements of the IEEE 802.15.4 standard -- 62.500 Hz,
+-40 ppm in the 2.4 GHz band -- the timing in beacon-enabled mode is not
standard compliant).

Status (last updated 9/14/09)
-----------------------------

Missing functionality:
- GTS
- security services
- PAN ID conflict notification/resolution
- indirect transmissions: frames are not kept in transaction queue 
  in case CSMA-CA algorithm fails

Known Issues:
- resetting the MAC during operation (via MLME_RESET) has not been tested
- if initial beacon Tx timestamp is invalid, the coordinator will hang 
- frame pending flags are (need to be) always set in the ACK headers
- transmitting coordinator realignment frames has not been tested
- using an incoming and outgoing superframe at the same time has not been tested
- during an ongoing CSMA-CA transmission incoming frames are ignored
- on a beacon-enabled PAN: if the device cannot find the beacon the DATA frame 
  is not transmitted (but it should be transmitted using unslotted CSMA-CA, see 
  Sect. 7.5.6.1 "Transmission")

Implementation 
--------------

MAC implementation: tinyos-2.x/tos/lib/mac/tkn154
MAC interfaces: tinyos-2.x/tos/lib/mac/tkn154/interfaces
CC2420 driver: tinyos-2.x/tos/chips/cc2420_tkn154
TelosB "platform glue" code: tinyos-2.x/tos/platforms/telosb/mac/tkn154
micaZ "platform glue" code: tinyos-2.x/tos/platforms/micaz/mac/tkn154
Example applications: tinyos-2.x/apps/tests/tkn154

Note: TEP3 recommends that interface names "should be mixed case, starting
upper case". To match the syntax used in the IEEE 802.15.4 standard the
interfaces provided by the MAC to the next higher layer deviate from this
convention (they are all caps, e.g. MLME_START).

Documentation
-------------

A technical report on TKN15.4 is available here:
http://www.tkn.tu-berlin.de/publications/papers/TKN154.pdf

TKN15.4 is the basis for the implementation of the TinyOS 15.4 WG:
http://tinyos.stanford.edu:8000/15.4_WG

Copyright
---------

This work was supported by the European Commision within the 6th Framework
Programme ICT Project ANGEL (Reference: 033506) and within the 7th Framework
Programme ICT Project CONET (Reference: 224053).

Author: Jan-Hinrich Hauer <hauer@tkn.tu-berlin.de>

/*
 * Copyright (c) 2009, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

