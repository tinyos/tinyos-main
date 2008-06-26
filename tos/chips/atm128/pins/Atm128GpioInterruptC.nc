/// $Id: Atm128GpioInterruptC.nc,v 1.5 2008-06-26 04:39:03 regehr Exp $

/**
 * @author Phil Levis
 */
generic module Atm128GpioInterruptC() @safe() {

  provides interface GpioInterrupt as Interrupt;
  uses interface HplAtm128Interrupt as Atm128Interrupt;

}

implementation {

  error_t enable( bool rising ) {
    atomic {
      call Atm128Interrupt.disable();
      call Atm128Interrupt.clear();
      call Atm128Interrupt.edge( rising );
      call Atm128Interrupt.enable();
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
    call Atm128Interrupt.disable();
    return SUCCESS;
  }

  async event void Atm128Interrupt.fired() {
    signal Interrupt.fired();
  }

}
