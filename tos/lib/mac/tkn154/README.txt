This directory contains "TKN15.4", a platform-independent IEEE 802.15.4-2006
MAC implementation. The code is in alpha state, under active development, but
most of the functionality described in the standard is implemented (and
cursorily tested). The MAC itself is platform-independent, but it requires
(1) a suitable radio driver, (2) Alarms/Timers with symbol precision and (3)
some "platform glue" code (defining guard times, etc.). Currently the only
supported platform is TelosB (however: without additional hardware support on
TelosB the timing in beacon-enabled mode is not standard compliant).

Status 6/16/08
--------------

missing functionality:
- security (not planned)
- GTS (not planned)
- PAN ID conflict resolution
- multiple indirect transmissions to the same destination

missing documentation:
- overview on the architecture of TKN15.4
- porting TKN15.4 to a new platform
- ...

Implementation 
--------------

MAC implementation: tinyos-2.x/tos/lib/mac/tkn154
MAC interfaces: tinyos-2.x/tos/lib/mac/tkn154/interfaces
CC2420 driver: tinyos-2.x/tos/chips/cc2420_tkn154
TelosB "platform glue" code: tinyos-2.x/tos/platforms/telosb/mac/tkn154
Example applications: tinyos-2.x/apps/tests/tkn154

Copyright
---------

This work was supported by the the European Commision within the 6th Framework
Project 2005-IST-5-033406-STP (ANGEL project)

Author: Jan-Hinrich Hauer <hauer@tkn.tu-berlin.de>

/*
 * Copyright (c) 2008, Technische Universitaet Berlin
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

