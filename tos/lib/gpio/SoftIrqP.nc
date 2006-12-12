/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Matt Miller, Crossbow <mmiller@xbow.com>
 *  @author Martin Turon, Crossbow <mturon@xbow.com>
 *
 *  $Id: SoftIrqP.nc,v 1.4 2006-12-12 18:23:28 vlahan Exp $
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
