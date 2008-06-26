
/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Implementation of the GPIO interrupt abstraction for
 * the TI MSP430 microcontroller.
 *
 * @author Jonathan Hui
 * @author Joe Polastre
 * @see  Please refer to TEP 117 for more information about this component and its
 *          intended use.
 */

generic module Msp430InterruptC() @safe() {

  provides interface GpioInterrupt as Interrupt;
  uses interface HplMsp430Interrupt as HplInterrupt;

}

implementation {

  error_t enable( bool rising ) {
    atomic {
      call Interrupt.disable();
      call HplInterrupt.edge( rising );
      call HplInterrupt.enable();
    }
    return SUCCESS;
  }

  async command error_t Interrupt.enableRisingEdge() {
    return enable( TRUE );
  }

  async command error_t Interrupt.enableFallingEdge() {
    return enable( FALSE );
  }

  async command error_t Interrupt.disable() {
    atomic {
      call HplInterrupt.disable();
      call HplInterrupt.clear();
    }
    return SUCCESS;
  }

  async event void HplInterrupt.fired() {
    call HplInterrupt.clear();
    signal Interrupt.fired();
  }

}
