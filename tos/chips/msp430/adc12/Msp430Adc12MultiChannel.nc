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
 * $Revision: 1.3 $
 * $Date: 2008-04-07 09:41:55 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This interface provides access to the ADC12 on the level of HAL. It can be
 * used to sample up to 16 (different) ADC channels. It separates between
 * configuration and data collection: every time a client has been granted
 * access to the ADC subsystem (via the Resource interface), it first has to
 * configure the ADC.  Afterwards the client may call getData() more than once
 * without reconfiguring the ADC in between (if the client has not released the
 * ADC via the Resource interface), i.e.<p>
 * 
 *    configure() -> ( getData() -> dataReady() )*
 *
 * @author Jan Hauer 
 */

#include "Msp430Adc12.h" 
interface Msp430Adc12MultiChannel 
{   

  /** 
   * Configures the ADC to perform conversion(s) on multiple channels.  Any
   * previous configuration will be overwritten.  If SUCCESS is returned
   * calling <code>getData()</code> will start the conversion immediately and a
   * <code>dataReady()</code> event will be signalled with the conversion
   * result when the conversion has finished.
   *
   * @param config Main ADC12 configuration and configuration of the first
   * channel 
   *
   * @param memctl List of additional channels and respective reference
   * voltages
   *
   * @param numMemctl Number of entries in the list
   * 
   * @param buffer Buffer to store the conversion results, it must have
   * numSamples entries. Results will be stored in the order the channels where
   * specified.
   *
   * @param numSamples Total number of samples. Note: numSamples %
   * (numMemctl+1) must be zero. For example, to sample every channel twice use
   * numSamples = (numMemctl+1) * 2
   *
   * @param jiffies Sampling period in terms of clock ticks of "sampcon_ssel"
   * and input divider "sampcon_id".
   *
   * @return SUCCESS means that the ADC was configured successfully and
   * <code>getData()</code> can be called to start the conversion.
   */

  async command error_t configure(const msp430adc12_channel_config_t *config,
      adc12memctl_t *memctl, uint8_t numMemctl, uint16_t *buffer, 
      uint16_t numSamples, uint16_t jiffies);

  /** 
   * Starts sampling the adc channels using the configuration as specified by
   * the last call to <code>configure()</code>.
   *
   * @return SUCCESS means that the conversion was started successfully and an
   * event dataReady() will be signalled. Otherwise no event will be signalled.
   */ 
  async command error_t getData();
  
  /** 
   * Conversion results are ready. Results are stored in the buffer in the
   * order the channels where specified in the <code>configure()</code>
   * command, i.e. every (numMemctl+1)-th entry maps to the same channel. 
   * 
   * @param buffer Conversion results (lower 12 bit are valid, respectively).
   * @param numSamples Number of results stored in <code>buffer</code> 
   */    
  async event void dataReady(uint16_t *buffer, uint16_t numSamples); 

}

