/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
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
 *
 *  @author Matt Miller, Crossbow <mmiller@xbow.com>
 *  @author Martin Turon, Crossbow <mturon@xbow.com>
 *
 *  $Id: SoftIrqP.nc,v 1.5 2010-06-29 22:07:47 scipio Exp $
 */

/**
 * Interrupt emulation interface access for GPIO pins.
 *
 * @param  interval   How often to check soft irq pin in msec
 */
generic module SoftIrqP (uint8_t interval)
{
    provides interface Interrupt as SoftIrq;
    
    uses {
	interface Timer<TMilli> as IrqTimer;
	interface GeneralIO as IrqPin;
    }
}
implementation
{
    norace struct {
	uint8_t final : 1;
	uint8_t last  : 1;
    } state;

    // ************* SoftIrq Interrupt handlers and dispatch *************
  
    /**
     * Enable an edge interrupt on a SoftIrq pin that is not capable of 
     * external hardware INTERRUPT.  Best we can do is poll periodically 
     * and monitor line level changes
     */
    async command error_t SoftIrq.startWait(bool low_to_high) {	
	atomic { state.final = low_to_high; }    // save state we await
	state.last = call IrqPin.get();          // get current state
	call IrqTimer.startOneShotNow(interval); // wait interval in msec
	return SUCCESS;
    }
    
    /**
     * Timer Event fired so now check SoftIrq pin level
     */
    event void IrqTimer.fired() {
	uint8_t  l_state = call IrqPin.get();

	if ((state.last != state.final) && 
	    (state.final == l_state)) {
	    // If we found an edge, fire SoftIrq!
	    signal SoftIrq.fired();
        } 

	// Otherwise, restart timer and try again
	state.last = l_state;
	return call IrqTimer.startOneShotNow(interval);
    }  
    
    /**
     * disables Irq interrupts
     */
    async command error_t SoftIrq.disable() {
	call IrqTimer.stop();
	return SUCCESS;
    }
    
    //default async event void SoftIrq.fired() { return FAIL; }
}
