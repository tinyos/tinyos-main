/* $Id: CC1000SquelchP.nc,v 1.6 2010-06-29 22:07:44 scipio Exp $
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
  
module CC1000SquelchP @safe()
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
