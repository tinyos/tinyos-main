/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:39 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This component allows a client to access the MSP430 ADC12
 * (12-bit analog-to-digital converter) via the <code>ReadStream</code>
 * interface. A client must wire the <code>Msp430Adc12Config</code> interface
 * to a component that returns its ADC12 configuration data. Depending on the
 * REF_VOLT_AUTO_CONFIGURE switch (defined in Msp430Adc12.h) the internal
 * reference voltage generator is automatically enabled if and only if the
 * configuration data includes VREF as reference voltage.
 *
 * @author Jan Hauer
 * @see  Please refer to TEP 101 for more information about this component and its
 *          intended use.
 */

#include <Msp430Adc12.h>
generic configuration AdcReadStreamClientC() {
  provides interface ReadStream<uint16_t>;
  uses interface Msp430Adc12Config;
} implementation {
  components AdcC,
#ifdef REF_VOLT_AUTO_CONFIGURE     
             new Msp430Adc12RefVoltAutoClientC() as Msp430AdcClient;
#else
             new Msp430Adc12ClientC() as Msp430AdcClient;
#endif

  enum {
    RSCLIENT = unique(ADCC_READ_STREAM_SERVICE),
  };

  ReadStream = AdcC.ReadStream[RSCLIENT];
  Msp430Adc12Config = AdcC.ConfigReadStream[RSCLIENT];
  AdcC.SingleChannelReadStream[RSCLIENT] -> Msp430AdcClient.Msp430Adc12SingleChannel;
  AdcC.ResourceReadStream[RSCLIENT] -> Msp430AdcClient.Resource;
#ifdef REF_VOLT_AUTO_CONFIGURE
  Msp430Adc12Config = Msp430AdcClient.Msp430Adc12Config;
#endif
}
  
