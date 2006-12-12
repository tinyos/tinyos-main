/* 
 * Copyright (c) 2004, Technische Universitaet Berlin All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.  - Redistributions in
 * binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.  - Neither the name of the
 * Technische Universitaet Berlin nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $ $Date: 2006-12-12 18:23:07 $ @author: Jan Hauer
 * <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
 
/** 
 * This component realizes the HAL1 representation and allows an
 * MSP430-specific client to access the MSP430 ADC12 (12-bit analog-to-digital
 * converter) via the <code>Msp430Adc12SingleChannel</code> and
 * <code>Resource</code> interface.  According to TEP 108 a client must reserve
 * the ADC before using it via the <code>Resource</code> interface (otherwise
 * the request will fail). In contrast to the <code>Msp430Adc12ClientC</code>
 * the <code>Msp430Adc12RefVoltAutoClientC</code> automatically enables the
 * internal reference voltage generator if and only if the configuration data
 * defined via the <code>Msp430Adc12Config</code> interface includes VREF as
 * reference voltage. I.e. the <code>Resource.granted()</code> event implies
 * that the reference voltage is stable. 
 * 
 * @author Jan Hauer
 * @see  Please refer to TEP 101 for more information about this component and its
 *          intended use.
 */

generic configuration Msp430Adc12RefVoltAutoClientC()
{
  provides interface Resource;
  provides interface Msp430Adc12SingleChannel;
  uses interface Msp430Adc12Config;
} implementation {
  components Msp430Adc12C, Msp430RefVoltArbiterC;

  enum {
    ID = unique(MSP430ADC12_RESOURCE),
  };
  Resource = Msp430RefVoltArbiterC.ClientResource[ID];
  Msp430Adc12SingleChannel = Msp430Adc12C.SingleChannel[ID];
  
  Msp430RefVoltArbiterC.AdcResource[ID] -> Msp430Adc12C.Resource[ID];
  Msp430Adc12Config = Msp430RefVoltArbiterC.Config[ID]; 
}
