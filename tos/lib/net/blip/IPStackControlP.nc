
module IPStackControlP {
  provides interface SplitControl;
  uses {
    interface StdControl;
    interface StdControl as RoutingControl;
    interface SplitControl as SubSplitControl;
    interface IPAddress;
  }
} implementation {

  command error_t SplitControl.start() {
    return call SubSplitControl.start();
  }

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

  command error_t SplitControl.stop() {
    call StdControl.stop();
    call RoutingControl.stop();

    return call SubSplitControl.stop();
  }

  event void SubSplitControl.stopDone(error_t error) {
    signal SplitControl.stopDone(error);
  }
  
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
