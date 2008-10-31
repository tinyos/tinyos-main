// $Id: LocalIeeeEui64C.nc,v 1.1 2008-10-31 17:04:03 sallai Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
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
