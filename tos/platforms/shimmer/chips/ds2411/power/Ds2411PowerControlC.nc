
/* Power control module that allows the shimmer platform to power gate the
 * DS2411.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration Ds2411PowerControlC {
  provides {
    interface StdControl;
  }
}

implementation {
  components Ds2411PowerControlP as PowerCtlP;

  // GPIO pin that provides VCC for the DS2411
  components HplMsp430GeneralIOC as Hpl;
  components new Msp430GpioC() as MspGpio;
  MspGpio.HplGeneralIO -> Hpl.Port23;

  PowerCtlP.pin -> MspGpio.GeneralIO;

  StdControl = PowerCtlP.StdControl;
}

