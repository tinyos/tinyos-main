/* $Id: MAX136xC.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $ */
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
#include "MAX136x.h"

generic configuration MAX136xC() {
  provides interface Read<max136x_data_t> as ADC;
  provides interface HalMAX136xAdvanced;
  provides interface SplitControl;
}

implementation {
  components new HalMAX136xReaderP();
  components HalMAX136xControlP;

  ADC = HalMAX136xReaderP.ADC;

  enum { ADC_KEY = unique("MAX136x.Resource"),
	 ADV_KEY = unique("MAX136x.Resource"),
	 READER_ID = unique("MAX136x.HplAccess"),
  };

  components MAX136xInternalC;
  HalMAX136xReaderP.MAX136xResource -> MAX136xInternalC.Resource[ADC_KEY];
  HalMAX136xReaderP.HplMAX136x -> MAX136xInternalC.HplMAX136x[READER_ID];
  HalMAX136xControlP.Resource -> MAX136xInternalC.Resource[ADV_KEY];
  HalMAX136xAdvanced = HalMAX136xControlP;

  SplitControl = MAX136xInternalC;
}
