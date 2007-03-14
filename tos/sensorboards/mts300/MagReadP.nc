// $Id: MagReadP.nc,v 1.1 2007-03-14 05:38:37 pipeng Exp $

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

configuration MagReadP 
{
  provides 
  {
    interface Mag;
    interface Read<uint16_t> as MagX[uint8_t client];
    interface Read<uint16_t> as MagY[uint8_t client];
  }
  uses
  {
    interface Read<uint16_t> as ActualX[uint8_t client];
    interface Read<uint16_t> as ActualY[uint8_t client];
  }
}
implementation
{
  components MagConfigP,
    new ArbitratedReadC(uint16_t) as AdcX,
    new ArbitratedReadC(uint16_t) as AdcY;

  Mag = MagConfigP;

  MagX = AdcX;
  AdcX.Resource -> MagConfigP;
  AdcX.Service = ActualX;

  MagY = AdcY;
  AdcY.Resource -> MagConfigP;
  AdcY.Service = ActualY;
}
