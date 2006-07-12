/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/**
 * Interface for control of interrupt-related  functions
 * on the XE1205 radio. 
 *
 * The current 2.x XE1205 driver is only intended for use of the radio in 
 * buffered mode - therefore IRQ settings for non-buffered mode are not exposed.
 *
 * @author Henri Dubois-Ferriere
 */


interface XE1205IrqConf {

#include "XE1205.h"

  /* 
   * Set IRQ0 sources in Rx mode. 
   *
   * @param src IRQ source.
   * @return SUCCESS if configuration done ok, error status otherwise.
   *
   */
  async command error_t setRxIrq0Source(xe1205_rx_irq0_src_t src);

  /* 
   * Set IRQ1 sources in Rx mode. 
   *
   * @param src IRQ source.
   * @return SUCCESS if configuration done ok, error status otherwise.
   *
   */
  async command error_t setRxIrq1Source(xe1205_rx_irq1_src_t src);

  /* 
   * Set IRQ1 source in Tx mode. 
   *
   * @param haveResource: if TRUE, bus is assumed to be already owned by the caller.
   * @param src IRQ source.
   * @return SUCCESS if configuration done ok, error status otherwise.
   *
   */
  async command error_t setTxIrq1Source(xe1205_tx_irq1_src_t src);


  /**
   * Clear FIFO overrun flag.
   *
   * @param haveResource: if TRUE, bus is assumed to be already owned by the caller.
   * @return SUCCESS if operation done ok, error status otherwise.
   *
   */
  async command error_t clearFifoOverrun(bool haveResource);
  
  /**
   * Get FIFO overrun flag.
   *
   * @param haveResource: if TRUE, bus is assumed to be already owned by the caller.
   * @param fifooverun will be written with 1 if the FIFO overran, 0 else.
   * @return SUCCESS if operation done ok, error status otherwise.
   *
   */
  async command error_t getFifoOverrun(bool haveResource, bool* fifooverrun);

  /**
   * Arm the pattern detector (clear Start_detect flag).
   *
   * @return SUCCESS if operation done ok, error status otherwise.
   *
   */
  async command error_t armPatternDetector(bool haveResource);
  
  
}
