/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Msp430InternalVoltageC is the voltage sensor available on the
 * msp430-based platforms.
 *
 * To convert from ADC counts to actual voltage, divide by 4096 and
 * multiply by 3.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2008-09-11 19:59:50 $
 */

/**
 * Port to Tosthreads
 *
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

generic configuration BlockingMsp430InternalVoltageC() {
  provides {
    interface BlockingRead<uint16_t>;
    interface BlockingReadStream<uint16_t>;
  }
}

implementation {
  components new BlockingAdcReadClientC();
  BlockingRead = BlockingAdcReadClientC;

  components new BlockingAdcReadStreamClientC();
  BlockingReadStream = BlockingAdcReadStreamClientC;

  components Msp430InternalVoltageP;
  BlockingAdcReadClientC.AdcConfigure -> Msp430InternalVoltageP;
  BlockingAdcReadStreamClientC.AdcConfigure -> Msp430InternalVoltageP;
}
