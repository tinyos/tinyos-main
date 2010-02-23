// $Id: CachedIeeeEui64C.nc,v 1.1 2010-02-23 06:45:38 sdhsdh Exp $
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
 * Cache an EUI 64 at initialization time and return the cached value for
 * subsequent queries.
 */
configuration CachedIeeeEui64C {
  uses interface LocalIeeeEui64 as SubIeeeEui64;
  provides interface LocalIeeeEui64;
} implementation {
  components CachedIeeeEui64P, MotePlatformC;

  MotePlatformC.SubInit -> CachedIeeeEui64P.Init;

  SubIeeeEui64 = CachedIeeeEui64P;
  LocalIeeeEui64 = CachedIeeeEui64P;

}
