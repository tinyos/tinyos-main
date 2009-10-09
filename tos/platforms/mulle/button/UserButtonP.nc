/**
 * Implementation of the user button for the Mulle platform extension board.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include <UserButton.h>

module UserButtonP {
  provides interface Get<button_state_t>;
  provides interface Notify<button_state_t>;
  provides interface Init;
  
  uses interface GeneralIO;
  uses interface GpioInterrupt;
}
implementation {
  
  command error_t Init.init()
  {
    call GeneralIO.makeInput();
    call GeneralIO.clr();
  }
  
  command button_state_t Get.get()
  { 
    if ( call GeneralIO.get() )
    {
      return BUTTON_PRESSED;
    } 
    else 
    {
      return BUTTON_RELEASED;
    }
  }

  command error_t Notify.enable()
  {
    return call GpioInterrupt.enableRisingEdge();
  }

  command error_t Notify.disable()
  {
    return call GpioInterrupt.disable();
  }

  async event void GIRQ.fired()
  {
      signal Notify.notify( BUTTON_PRESSED );
  }
}
