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
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This interface exports access to the ADC12 on the level of
 * HAL1 on a per-channel basis. It allows to sample a channel once or
 * repeatedly (and signal an event per conversion result) or perform multiple
 * conversions for the same channel once or repeatedly (and signal an event per
 * multiple conversion results). It does not allow to sample different channels
 * with the same command.
 *
 * @author Jan Hauer
 * @see  Please refer to TEP 101 for more information about this component and its
 *          intended use.
 */

#include <Msp430Adc12.h> 
interface Msp430Adc12SingleChannel 
{   
  /** 
   * Samples an ADC channel once. If SUCCESS is returned, an event
   * <code>singleDataReady()</code> will be signalled with the conversion
   * result. Otherwise <code>singleDataReady()</code> will not be signalled.
   *
   * @param config ADC12 configuration data.  
   * @return SUCCESS means conversion data will be signalled in
   * <code>singleDataReady()</code>.
   */
  async command error_t getSingleData(const msp430adc12_channel_config_t *config);

  /** Samples an ADC channel repeatedly and signals an event
   * <code>singleDataReady()</code> after every single conversion.  Conversion
   * result are signalled, until the client returns <code>FAIL</code> in the
   * <code>singleDataReady()</code> event handler.  If this command does not
   * return SUCCESS then <code>singleDataReady()</code> will not be
   * signalled.<br><br> Successive conversions are performed as quickly as
   * possible if <code>jiffies</code> equals zero. Otherwise
   * <code>jiffies</code> define the time between successive conversions in
   * terms of clock ticks of "sampcon_ssel" and input divider "sampcon_id" as
   * specified in the <code>config</code> parameter.
   * 
   * @param config ADC12 configuration data.  
   * @param jiffies Sampling rate in terms of clock ticks of
   * "sampcon_ssel" and input divider "sampcon_id".
   * @return SUCCESS means conversion data will be signalled in
   * <code>singleDataReady()</code> until the client returns <code>FAIL</code>.
   */
  async command error_t getSingleDataRepeat(const msp430adc12_channel_config_t *config, 
      uint16_t jiffies);

 /** 
  *
  * Samples an ADC channel multiple times and signals one event
  * <code>multipleDataReady()</code> with all conversion results.  If SUCCESS
  * is returned, the event <code>multipleDataReady</code> is signalled after
  * the buffer is filled with conversion results, otherwise
  * <code>multipleDataReady()</code> will not be signalled.  <br><br>
  * Successive conversions are performed as quickly as possible if
  * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> define the
  * time between successive conversions in terms of clock ticks of
  * "sampcon_ssel" and input divider "sampcon_id" as specified in the
  * <code>config</code> parameter.
  *
  * @param config ADC12 configuration data.  
  * @param jiffies Sampling rate in terms of clock ticks of
  * "sampcon_ssel" and input divider "sampcon_id".
  * @param buffer The buffer to store the conversion results. It must have a
  * minimum size of <code>numSamples * 2</code> byte !  
  * @param numSamples Number of samples to take, buffer size must be greater or
  * equal than <code>numSamples * 2</code> byte !  
  * @return SUCCESS means conversion data will be signalled in
  * <code>singleDataReady()</code>.
  */ 
  async command error_t getMultipleData( const msp430adc12_channel_config_t *config,
      uint16_t *buffer, uint16_t numSamples, uint16_t jiffies);

 /** 
  *
  * Samples an ADC channel up to 16 times and signals an event
  * <code>multipleDataReady()</code> with all conversion results repeatedly.
  * If SUCCESS is returned, the event <code>multipleDataReady</code> is
  * signalled after the buffer is filled with the first (up to 16) conversion
  * results, otherwise <code>multipleDataReady()</code> will not be signalled.
  * The conversion result are signalled repeatedly, until the client returns
  * <code>FAIL</code> in the <code>multipleDataReady()</code> event handler.
  * <br><br> Successive conversions are performed as quickly as possible if
  * <code>jiffies</code> equals zero. Otherwise <code>jiffies</code> define the
  * time between successive conversions in terms of clock ticks of
  * "sampcon_ssel" and input divider "sampcon_id" as specified in the
  * <code>config</code> parameter.
  *
  * @param config ADC12 configuration data.  @param jiffies Jiffies in terms of
  * clock ticks of "sampcon_ssel" and input divider "sampcon_id".  @param
  * buffer The buffer to store the conversion results. It must have a minimum
  * size of <code>numSamples * 2</code> byte !  
  * @param jiffies Sampling rate in terms of clock ticks of
  * "sampcon_ssel" and input divider "sampcon_id".
  * @param numSamples Number of samples to take, 1 <= numSamples <= 16, buffer
  * size must be greater or equal than <code>numSamples * 2</code> byte !  
  * @return SUCCESS means conversion data will be signalled in
  * <code>singleDataReady()</code> until the client returns <code>FAIL</code>.
  */
  async command error_t getMultipleDataRepeat(const msp430adc12_channel_config_t *config, 
      uint16_t *buffer, uint8_t numSamples, uint16_t jiffies);

  /** 
   * Data from a call to <code>getSingleData()</code> or
   * <code>getSingleDataRepeat()</code> is ready. In the first case the return
   * value is ignored, in the second it defines whether another conversion
   * takes place (<code>SUCCESS()</code>) or not (<code>FAIL</code>).
   * 
   * @param data Conversion result (lower 12 bit).  
   * @return If this event is signalled as response to a call to
   * <code>getSingleDataRepeat()</code> then <code>SUCCESS</code> results in
   * another sampling and <code>FAIL</code> stops the repeated sampling.
   * Otherwise the return value is ignored.
   */  
  async event error_t singleDataReady(uint16_t data);

  /** 
   * Data from a call to <code>getMultipleData()</code> or
   * <code>getMultipleDataRepeat()</code> is ready. In the first case the
   * return value is ignored, in the second a non-zero pointer defines where to
   * store the next <code>numSamples</code> conversion results and a null
   * pointer stops the repeated conversion mode. 
   * 
   * @param buffer Conversion results (lower 12 bit are valid).  
   * @param numSamples Number of samples stored in <code>buffer</code> 
   * @return A null pointer stops a repeated conversion mode. Any non-zero
   * value is interpreted as the next buffer, which must have size
   * <code>numSamples 2</code> byte!). Ignored if this event is a response to
   * <code>getMultipleData()</code>.
   */    
  async event uint16_t* multipleDataReady(uint16_t *buffer, uint16_t
      numSamples); 
}

