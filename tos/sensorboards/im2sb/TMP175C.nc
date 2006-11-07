/* $Id: TMP175C.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $ */
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

generic configuration TMP175C() {
  provides interface Read<uint16_t> as Temperature;
  provides interface HalTMP175Advanced;
  provides interface SplitControl;
  //provides interface Init;
}

implementation {
  components new HalTMP175ReaderP();
  components HalTMP175ControlP;
  Temperature = HalTMP175ReaderP.Temperature;

  enum { TMP_KEY = unique("TMP175.Resource"),
	 ADV_KEY = unique("TMP175.Resource"),
	 READER_ID = unique("TMP175.HplAccess"),
  };

  components TMP175InternalC;
  HalTMP175ReaderP.TMP175Resource -> TMP175InternalC.Resource[TMP_KEY];
  HalTMP175ControlP.TMP175Resource -> TMP175InternalC.Resource[ADV_KEY];
  HalTMP175ReaderP.HplTMP175 -> TMP175InternalC.HplTMP175[READER_ID];
  HalTMP175Advanced = HalTMP175ControlP.HalTMP175Advanced;

  SplitControl = TMP175InternalC;
}
