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
 * $Revision: 1.4 $
 * $Date: 2006/12/12 18:23:06 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This component virtualizes the HIL of ADC12 on MSP430. A client must wire
 * <code>AdcConfigure</code> to a component that returns the client's adc
 * configuration data.
 *
 * @author Jan Hauer 
 * @see  Please refer to the README.txt and TEP 101 for more information about 
 * this component and its intended use.
 */

#include <Msp430Adc12.h>
generic configuration AdcReadClientC() {
  provides interface Read<uint16_t>;
  uses interface AdcConfigure<const msp430adc12_channel_config_t*>;
} implementation {
  components AdcP,
#ifdef REF_VOLT_AUTO_CONFIGURE     
             // if the client configuration requires a stable 
             // reference voltage, the reference voltage generator 
             // is automatically enabled
             new Msp430Adc12ClientAutoRVGC() as Msp430AdcClient;
#else
             new Msp430Adc12ClientC() as Msp430AdcClient;
#endif

  enum {
    CLIENT = unique(ADCC_SERVICE),
  };

  Read = AdcP.Read[CLIENT];
  AdcConfigure = AdcP.Config[CLIENT];
  AdcP.SingleChannel[CLIENT] -> Msp430AdcClient.Msp430Adc12SingleChannel;
  AdcP.ResourceRead[CLIENT] -> Msp430AdcClient.Resource;
#ifdef REF_VOLT_AUTO_CONFIGURE
  AdcConfigure = Msp430AdcClient.AdcConfigure;
#endif 
}
  
