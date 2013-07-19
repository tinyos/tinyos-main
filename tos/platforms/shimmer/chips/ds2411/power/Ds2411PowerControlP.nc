
/* Power control module that allows the shimmer platform to power gate the
 * DS2411.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

module Ds2411PowerControlP {
  provides {
    interface StdControl;
  }
  uses {
    interface GeneralIO as pin;
  }
}

implementation {
  command error_t StdControl.start () {
    call pin.set();
    return SUCCESS;
  }

  command error_t StdControl.stop () {
    call pin.clr();
    return SUCCESS;
  }
}

