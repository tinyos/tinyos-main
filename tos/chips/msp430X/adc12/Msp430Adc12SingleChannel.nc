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
 * $Revision: 1.6 $
 * $Date: 2008/06/27 18:05:23 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * 
 * This interface provides access to the ADC12 on the level of HAL. It can be
 * used to sample a single adc channel once or repeatedly (one event is
 * signalled per conversion result) or perform multiple conversions for a
 * single channel once or repeatedly (one event is signalled per multiple
 * conversion results). It cannot be used to sample different adc channels with
 * a single command (use the Msp430Adc12MultiChannel interface instead).
 * Sampling a channel requires calling a sequence of two commands, configureX()
 * and getData(), where X is either 'Single', 'SingleRepeat', 'Multiple' or
 * 'MultipleRepeat'. Conversion results will be signalled by the
 * dataReadySingle() or dataReadyMultiple() event, depending on the previous
 * configuration, i.e. there are four possible sequences:
 * 
 * <p> configureSingle()          -> ( getData() -> singleDataReady() )*
 * <p> configureSingleRepeat()    -> ( getData() -> singleDataReady() )*
 * <p> configureMultiple()        -> ( getData() -> multipleDataReady() )*
 * <p> configureMultipleRepeat()  -> getData() -> multipleDataReady()
 *
 * <p> where configureX() and getData() are commands called by the client and
 * singleDataReady() and multipleDataReady() are events signalled back to the
 * client by the adc subsystem. Note that a configuration is valid until the
 * client reconfigures or releases the ADC (using the Resource interface),
 * except for configureMultipleRepeat(), which is only valid for a single call
 * to getData(). This means that after a successful configuration with, for
 * example, configureSingle() the client may call getData() more than once
 * without reconfiguring the ADC in between (if the client has not released the
 * ADC via the Resource interface).
 *
 * @author Jan Hauer 
 */

#include "Msp430Adc12.h" 
interface Msp430Adc12SingleChannel 
{   

  /** 
   * Configures the ADC to perform a single conversion. Any previous
   * configuration will be overwritten.  If SUCCESS is returned calling
   * <code>getData()</code> will start the conversion immediately and a
   * <code>singleDataReady()</code> event will be signalled with the conversion
   * result when the conversion has finished.
   *
   * @param config ADC12 configuration data.  
   *
   * @return SUCCESS means that the ADC was configured successfully and
   * <code>getData()</code> can be called to start the conversion.
   */
  async command error_t configureSingle(const msp430adc12_channel_config_t *ONE config);

  /** 
   * Configures the ADC for repeated single channel conversion mode. Any
   * previous configuration will be overwritten. If SUCCESS is returned calling
   * <code>getData()</code> will start sampling the adc channel periodically
   * (the first conversion is started immediately).  The sampling period is
   * specified by the <code>jiffies</code> parameter, which defines the time
   * between successive conversions in terms of clock ticks of clock source
   * "sampcon_ssel" and clock input divider "sampcon_id" as specified in the
   * <code>config</code> parameter. If jiffies is zero successive conversions
   * are performed as quickly as possible.  Conversion result are signalled
   * until the client returns <code>FAIL</code> in the
   * <code>singleDataReady()</code> event handler.
   * 
   * @param config ADC12 configuration data.  
   * @param jiffies Sampling period in terms of clock ticks of "sampcon_ssel" and
   * input divider "sampcon_id".
   *
   * @return SUCCESS means that the ADC was configured successfully and
   * <code>getData()</code> can be called to start with the first conversion.
   */
  async command error_t configureSingleRepeat(const msp430adc12_channel_config_t *ONE config, uint16_t jiffies);

  
  /** 
   * Configures the ADC for sampling a channel <code>numSamples</code> times
   * with a given sampling period. Any previous configuration will be
   * overwritten.  In contrast to the <code>configureSingleRepeat()</code>
   * command, this configuration means that only one event will be signalled
   * after all samples have been taken (which is useful for high-frequency
   * sampling). If SUCCESS is returned calling <code>getData()</code> will
   * start sampling the adc channel <code>numSamples</code> times and the first
   * conversion is started immediately. Conversion results are stored in a
   * buffer allocated by the client (the <code>buffer</code>
   * parameter). The sampling period is specified by the <code>jiffies</code>
   * parameter, which defines the time between successive conversions in terms
   * of clock ticks of clock source "sampcon_ssel" and clock input divider
   * "sampcon_id" as specified in the <code>config</code> parameter. If jiffies
   * is zero successive conversions are performed as quickly as possible. After
   * <code>numSamples</code> conversions an event
   * <code>multipleDataReady()</code> is signalled with the conversion results.
   *
   * @param config ADC12 configuration data.  
   * @param jiffies Sampling period in terms of clock ticks of "sampcon_ssel"
   * and input divider "sampcon_id".
   * @param buffer The user-allocated buffer in which the conversion results
   * will be stored. It must have at least <code>numSamples</code> entries,
   * i.e. it must have a size of at least <code>numSamples</code> * 2 byte.
   * @param numSamples Number of adc samples
   *
   * @return SUCCESS means that the ADC was configured successfully and
   * <code>getData()</code> can be called to start with the first conversion.
   */ 
  async command error_t configureMultiple( const msp430adc12_channel_config_t *ONE config, uint16_t *COUNT(numSamples) buffer, uint16_t numSamples, uint16_t jiffies);

  /** 
   *
   * Configures the ADC for sampling a channel multiple times repeatedly.  Any
   * previous configuration will be overwritten. In contrast to the
   * <code>configureSingleRepeat()</code> command this configuration means that
   * an event with <code>numSamples</code> conversion results will be
   * signalled, where 0 < <code>numSamples</code> <= 16. In contrast to the
   * <code>configureMultiple()</code> command, this configuration means that
   * <code>numSamples</code> conversion results will be signalled repeatedly
   * until the client returns <code>FAIL</code> in the
   * <code>multipleDataReady()</code> event handler. 
   *
   * If <code>configureMultipleRepeat()</code> returns SUCCESS calling
   * <code>getData()</code> will start the the first conversion immediately.
   * The sampling period is specified by the <code>jiffies</code> parameter,
   * which defines the time between successive conversions in terms of clock
   * ticks of clock source "sampcon_ssel" and clock input divider "sampcon_id"
   * as specified in the <code>config</code> parameter. If jiffies is zero
   * successive conversions are performed as quickly as possible. After
   * <code>numSamples</code> conversions an event
   * <code>multipleDataReady()</code> is signalled with <code>numSamples</code>
   * conversion results. If the client returns <code>SUCCESS</code> in the
   * <code>multipleDataReady()</code> event handler, <code>numSamples</code>
   * new conversions will be performed, otherwise not.
   *
   * @param config ADC12 configuration data.  
   * @param jiffies Sampling period in terms of clock ticks of "sampcon_ssel"
   * and input divider "sampcon_id".
   * @param buffer The user-allocated buffer in which the conversion results
   * will be stored. It must have at least <code>numSamples</code> entries,
   * i.e. it must have a size of at least <code>numSamples</code> * 2 byte.
   * @param numSamples Number of adc samples to take, 0 <
   * <code>numSamples</code> <= 16
   *
   * @return SUCCESS means that the ADC was configured successfully and
   * <code>getData()</code> can be called to start with the first conversion.
   */ 
  async command error_t configureMultipleRepeat(const msp430adc12_channel_config_t *ONE config, uint16_t *COUNT(numSamples) buffer, uint8_t numSamples, uint16_t jiffies);


  /** 
   * Starts sampling an adc channel using the configuration as specified by
   * the last call to any of the four available configuration commands.
   *
   * @return SUCCESS means that the conversion was started successfully and an
   * event singleDataReady() or multipleDataReady() will be signalled
   * (depending on the previous configuration). Otherwise no such event will be
   * signalled.
   */ 
  async command error_t getData();
  
  /** 
   * A single ADC conversion result is ready. If the ADC was configured with
   * the <code>configureSingle()</code> command, then the return value is
   * ignored. If the ADC was configured with the
   * <code>configureSingleRepeat()</code> command then the return value tells
   * whether another conversion should be performed (<code>SUCCESS()</code>) or
   * not (<code>FAIL</code>).
   * 
   * @param data Conversion result (lower 12 bit).  
   *
   * @return If this event is signalled as response to a call to
   * <code>configureSingleRepeat()</code> then <code>SUCCESS</code> results in
   * another sampling and <code>FAIL</code> stops the repeated sampling.
   * Otherwise the return value is ignored.
   */  
  async event error_t singleDataReady(uint16_t data);

  /** 
   * Multiple ADC conversion results are ready.  If the ADC was configured
   * with the <code>configureMultiple()</code> command, then the return value
   * is ignored. If the ADC was configured with the
   * <code>configureMultipleRepeat()</code> command then the returned pointer
   * defines where to store the next <code>numSamples</code>
   * conversion results (the client must make sure that the buffer is big
   * enough!).  Returning a null pointer means that the repeated conversion
   * mode will be stopped.
   * 
   * @param buffer Conversion results (lower 12 bit are valid, respectively).
   * @param numSamples Number of samples stored in <code>buffer</code> 
   *
   * @return
   * A null pointer stops a repeated conversion mode. Any non-zero value is
   * interpreted as the next buffer, which must have at least
   * <code>numSamples</code> entries. The return value is ignored if the ADC
   * was configured with <code>configureMultiple()</code>.
   */    
  async event uint16_t * COUNT_NOK(numSamples) multipleDataReady(uint16_t *COUNT(numSamples) buffer, uint16_t numSamples); 

}

