
/* Power control module that allows for different platforms to power gate
 * the DS2411 chip.
 * This implementation is just a dummy version that doesn't actually control
 * anything. However, if desired, a platform could override this version with
 * one that sets a particular pin high or whatever else is needed to activate
 * the ID chip.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

module Ds2411PowerControlC {
  provides {
    interface StdControl;
  }
}

implementation {
  command error_t StdControl.start () {
    return SUCCESS;
  }

  command error_t StdControl.stop () {
    return SUCCESS;
  }
}
