/* $Id: LIS3L02DQC.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "im2sb.h"

generic configuration LIS3L02DQC() {
  //provides interface Init;
  provides interface SplitControl;
  provides interface Read<uint16_t> as AccelX;
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;
  provides interface HalLIS3L02DQAdvanced;
}

implementation {
  components new HalLIS3L02DQReaderP();
  components HalLIS3L02DQControlP;
  AccelX = HalLIS3L02DQReaderP.AccelX;
  AccelY = HalLIS3L02DQReaderP.AccelY;
  AccelZ = HalLIS3L02DQReaderP.AccelZ;
  HalLIS3L02DQAdvanced = HalLIS3L02DQControlP.Advanced;
  
  enum { ACCELX_KEY = unique("LIS3L02DQ.Resource"),
	 ACCELY_KEY = unique("LIS3L02DQ.Resource"),
	 ACCELZ_KEY = unique("LIS3L02DQ.Resource"),
	 ADV_KEY = unique("LIS3L02DQ.Resource"),
	 READER_ID = unique("LIS3L02DQ.HplAccess"),
  };

  components LIS3L02DQInternalC;
  HalLIS3L02DQReaderP.AccelXResource -> LIS3L02DQInternalC.Resource[ACCELX_KEY];
  HalLIS3L02DQReaderP.AccelYResource -> LIS3L02DQInternalC.Resource[ACCELY_KEY];
  HalLIS3L02DQReaderP.AccelZResource -> LIS3L02DQInternalC.Resource[ACCELZ_KEY];
  HalLIS3L02DQControlP.Resource -> LIS3L02DQInternalC.Resource[ADV_KEY];
  HalLIS3L02DQReaderP.Hpl -> LIS3L02DQInternalC.HplLIS3L02DQ[READER_ID];

  SplitControl = LIS3L02DQInternalC;
}
