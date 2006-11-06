/* $Id: CC1000SquelchP.nc,v 1.2 2006-11-06 11:57:05 scipio Exp $
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include "CC1000Const.h"

/**
 * Clear threshold estimation based on RSSI measurements.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 */
  
module CC1000SquelchP
{
  provides {
    interface Init;
    interface CC1000Squelch;
  }
}
implementation
{
  uint16_t clearThreshold = CC1K_SquelchInit;
  uint16_t squelchTable[CC1K_SquelchTableSize];
  uint8_t squelchIndex, squelchCount;

  command error_t Init.init() {
    uint8_t i;

    for (i = 0; i < CC1K_SquelchTableSize; i++)
      squelchTable[i] = CC1K_SquelchInit;

    return SUCCESS;
  }

  command void CC1000Squelch.adjust(uint16_t data) {
    uint16_t squelchTab[CC1K_SquelchTableSize];
    uint8_t i, j, min; 
    uint32_t newThreshold;

    squelchTable[squelchIndex++] = data;
    if (squelchIndex >= CC1K_SquelchTableSize)
      squelchIndex = 0;
    if (squelchCount <= CC1K_SquelchCount)
      squelchCount++;  

    // Find 3rd highest (aka lowest signal strength) value
    memcpy(squelchTab, squelchTable, sizeof squelchTable);
    for (j = 0; ; j++)
      {
	min = 0;
	for (i = 1; i < CC1K_SquelchTableSize; i++)
	  if (squelchTab[i] > squelchTab[min])
	    min = i;
	if (j == 3)
	  break;
	squelchTab[min] = 0;
      }

    newThreshold = ((uint32_t)clearThreshold << 5) +
      ((uint32_t)squelchTab[min] << 1);
    atomic clearThreshold = newThreshold / 34;
  }

  async command uint16_t CC1000Squelch.get() {
    return clearThreshold;
  }

  command bool CC1000Squelch.settled() {
    return squelchCount > CC1K_SquelchCount;
  }
}
