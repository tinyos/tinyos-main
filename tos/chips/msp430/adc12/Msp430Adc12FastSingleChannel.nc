/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Revision: 1.3 $
 * $Date: 2006-12-12 18:23:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * In contrast to the Msp430Adc12SingleChannel interface this interface
 * separates between configuration and sampling of the ADC and therefore allows
 * to minimize the time between the call to getSingleData and the start of
 * the sampling.
 * 
 * @author Jan Hauer 
 * @see  Please refer to TEP 101.
 */

#include <Msp430Adc12.h> 
interface Msp430Adc12FastSingleChannel 
{   

  /** 
   * Configures the ADC hardware. If SUCCESS is returned, every subsequent call
   * to <code>getSingleData()</code> will start the sampling immediately with
   * the specified configuration.  However, the configuration is valid only
   * until the ADC is released via the Resource interface (which is provided in
   * conjunction with this interface), i.e. it must be configured every time
   * the Resource interface grants access to the ADC (otherwise the
   * configuration state is undefined).
   * 
   * @param config ADC12 configuration data.  
   *
   * @return SUCCESS means subsequent calls to <code>getSingleData()</code>
   * will use the configuration.
   */
  async command error_t configure(const msp430adc12_channel_config_t *config);
  
  /** 
   * Samples an ADC channel once with the configuration passed in
   * <code>configure()</code>. If SUCCESS is returned, an event
   * <code>singleDataReady()</code> will be signalled with the conversion
   * result. Otherwise <code>singleDataReady()</code> will not be signalled.
   *
   * @param config ADC12 configuration data.  @return SUCCESS means conversion
   * data will be signalled in <code>singleDataReady()</code>.
   */
  async command error_t getSingleData(); 
  
   /** 
    * Data from a call to <code>getSingleData()</code> is ready.
    * 
    * @param data Conversion result (lower 12 bit).  
    */  
  async event void singleDataReady(uint16_t data); 
}

