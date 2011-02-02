/*
 * Copyright (c) 2011 University of Utah. 
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:  
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 */

interface Sam3sDac
{
  /**
   * triggerEn: enable external trigger mode
   * triggerSel: select trigger source
   * wordTransfer: 1: word transfer, 0: half-word
   * sleep: 1: sleep mode, 0: normal mode
   * userSel: select channel
   * tagSelection: 1: bits 15-13 in data select channel
   * maxSpeed: 1: max speed mode enabled
   */
  command error_t configure(
      bool triggerEn,     
      uint8_t triggerSel, 
      bool wordTransfer,  
      bool sleep,         
      bool fastWakeUp,
      uint8_t refreshPeriod,
      uint8_t userSel,    
      bool tagSelection,  
      bool maxSpeed,      
      uint8_t startupTime);


  async command error_t enable(uint8_t channel);

  async command error_t disable(uint8_t channel);

  /**
   * Sets the DAC value. If wordTransfer is selected in the configuration,
   * then the lower half-word of data is one conversion value, and the upper
   * half-word a second. The DAC has a FIFO of up to 4 conversion values.
   *
   * If tagSelection is set, then the upper 15-13 bits of each half-word
   * indicate the channel.
   *
   * @return SUCCESS if ok, EBUSY if the DAC if the FIFO is full.
   */
  async command error_t set(uint32_t data);

}
