/* $Id: Tsl2561C.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $ */
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

generic configuration Tsl2561C() {
  provides interface Read<uint16_t> as BroadbandPhoto;
  provides interface Read<uint16_t> as IRPhoto;
  provides interface HalTsl2561Advanced;
  provides interface SplitControl; // this is for power control?
  //provides interface Init;
}
implementation {
  components new HalTsl2561ReaderP();
  components HalTsl2561ControlP;

  BroadbandPhoto = HalTsl2561ReaderP.BroadbandPhoto;
  IRPhoto = HalTsl2561ReaderP.IRPhoto;

  enum { BB_KEY = unique("Tsl2561.Resource"),
	 IR_KEY = unique("Tsl2561.Resource"),
	 ADV_KEY = unique("Tsl2561.Resource"),
	 READER_ID = unique("Tsl2561.HplAccess"),
  };

  components Tsl2561InternalC;
  HalTsl2561ReaderP.BroadbandResource -> Tsl2561InternalC.Resource[BB_KEY];
  HalTsl2561ReaderP.IRResource -> Tsl2561InternalC.Resource[IR_KEY];
  HalTsl2561ControlP.Resource -> Tsl2561InternalC.Resource[ADV_KEY];

  HalTsl2561ReaderP.HplTSL256x -> Tsl2561InternalC.HplTSL256x[READER_ID];

  HalTsl2561Advanced = HalTsl2561ControlP.HalTsl2561Advanced;

  // for debugging
  SplitControl = Tsl2561InternalC;
}

