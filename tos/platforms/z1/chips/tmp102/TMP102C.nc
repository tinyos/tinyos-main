/* $Id: TMP175C.nc,v 1.4 2006/12/12 18:23:45 vlahan Exp $ */
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
//#include "im2sb.h"

generic configuration TMP102C() {
  provides interface Read<uint16_t> as Temperature;
  provides interface HalTMP102Advanced;
  provides interface SplitControl;
}

implementation {
  components new HalTMP102ReaderP();
  components HalTMP102ControlP;
  Temperature = HalTMP102ReaderP.Temperature;

  enum { TMP_KEY = unique("TMP102.Resource"),
	 ADV_KEY = unique("TMP102.Resource"),
	 READER_ID = unique("TMP102.HplAccess"),
  };

  components TMP102InternalC;
  HalTMP102ReaderP.TMP102Resource -> TMP102InternalC.Resource[TMP_KEY];
  HalTMP102ControlP.TMP102Resource -> TMP102InternalC.Resource[ADV_KEY];
  HalTMP102ReaderP.HplTMP175 -> TMP102InternalC.HplTMP102[READER_ID];
  HalTMP102Advanced = HalTMP102ControlP.HalTMP102Advanced;

  SplitControl = TMP102InternalC;
}
