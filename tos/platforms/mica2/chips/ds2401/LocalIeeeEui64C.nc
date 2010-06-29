// $Id: LocalIeeeEui64C.nc,v 1.2 2010-06-29 22:07:54 scipio Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Janos Sallai
 */

/**
 * Mica2-specific wiring to access the DS2401 hardware ID chip through the
 * LocalIeeeEui64 interface. The CachedIeeeEui64C component reads the ID
 * during hardware initialization, caches it, and returns the cached value at
 * subsequent calls to LocalIeeeEui64.getId().
 */
configuration LocalIeeeEui64C {
  provides interface LocalIeeeEui64;
} implementation {
  components
    OneWireMasterC as OneWireC,
    HplDs2401C,
    BusyWaitMicroC,
    HplAtm128GeneralIOC,
    Ds2401ToIeeeEui64C,
    CachedIeeeEui64C;

  OneWireC.Pin -> HplAtm128GeneralIOC.PortA4;
  OneWireC.BusyWaitMicro -> BusyWaitMicroC.BusyWait;
  HplDs2401C.OneWire -> OneWireC;
  Ds2401ToIeeeEui64C.Hpl -> HplDs2401C;
  CachedIeeeEui64C.SubIeeeEui64 -> Ds2401ToIeeeEui64C;
  LocalIeeeEui64 = CachedIeeeEui64C;
}
