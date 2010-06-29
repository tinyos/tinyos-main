// $Id: GpioInterrupt.nc,v 1.5 2010-06-29 22:07:46 scipio Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
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
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Jonathan Hui
 * @author Joe Polastre
 * Revision:  $Revision: 1.5 $
 *
 * Provides a microcontroller-independent presentation of interrupts
 */


interface GpioInterrupt {

  /** 
   * Enable an edge based interrupt. Calls to these functions are
   * not cumulative: only the transition type of the last called function
   * will be monitored for.
   *
   *
   * @return SUCCESS if the interrupt has been enabled
   */
  async command error_t enableRisingEdge();
  async command error_t enableFallingEdge();

  /**  
   * Diables an edge interrupt or capture interrupt
   * 
   * @return SUCCESS if the interrupt has been disabled
   */ 
  async command error_t disable();

  /**
   * Fired when an edge interrupt occurs.
   *
   * NOTE: Interrupts keep running until "disable()" is called
   */
  async event void fired();

}
