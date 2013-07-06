
module IPStackControlP {
  provides interface SplitControl;
  uses {
    interface StdControl;
    interface StdControl as RoutingControl;
#ifndef BLIP_NO_RADIO
    interface SplitControl as SubSplitControl;
#endif
    interface IPAddress;
  }
} implementation {

  command error_t SplitControl.start() {
#ifndef BLIP_NO_RADIO
    return call SubSplitControl.start();
#else
    call StdControl.start();
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
#endif
  }

#ifndef BLIP_NO_RADIO
  event void SubSplitControl.startDone(error_t error) {
    struct in6_addr addr;
    if (error == SUCCESS) {
      call StdControl.start();
    }

    // if we have a global address, we can start any routing protocols now.
    if (call IPAddress.getGlobalAddr(&addr)) {
      call RoutingControl.start();
    }

    signal SplitControl.startDone(error);
  }
#endif

  command error_t SplitControl.stop() {
    call StdControl.stop();
    call RoutingControl.stop();

#ifndef BLIP_NO_RADIO
    return call SubSplitControl.stop();
#else
    return SUCCESS;
#endif
  }

#ifndef BLIP_NO_RADIO
  event void SubSplitControl.stopDone(error_t error) {
    signal SplitControl.stopDone(error);
  }
#endif

  event void IPAddress.changed(bool valid) {
    if (valid)
      call RoutingControl.start();
    else
      call RoutingControl.stop();
  }

 default command error_t StdControl.start() { return SUCCESS; }
 default command error_t StdControl.stop() { return SUCCESS; }
 default command error_t RoutingControl.start() { return SUCCESS; }
 default command error_t RoutingControl.stop() { return SUCCESS; }

}
