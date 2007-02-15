// $Id: MagC.nc,v 1.1 2007-02-15 10:33:37 pipeng Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
#include "mts300.h"

generic configuration MagC ()
{
  provides interface Init;
  provides interface StdControl;
  provides interface Read<uint16_t> as MagX;
  provides interface Read<uint16_t> as MagY;
  provides interface Mag;
}
implementation
{
  components MagConfigP,
    new AdcReadClientC() as AdcX,
    new AdcReadClientC() as AdcY;

  Init = MagConfigP;
	StdControl = MagConfigP;
  Mag = MagConfigP;

  MagX = AdcX;
  AdcX.Atm128AdcConfig -> MagConfigP.ConfigX;
  AdcX.ResourceConfigure -> MagConfigP.ResourceX;

  MagY = AdcY;
  AdcY.Atm128AdcConfig -> MagConfigP.ConfigY;
  AdcY.ResourceConfigure -> MagConfigP.ResourceY;
}

