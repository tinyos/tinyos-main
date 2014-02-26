/*
 * Module provides interfaces for turning on and off different parts of the
 * networking stack.
 *
 * @author Stephen Dawson-Haggerty <stevedh@cs.berkeley.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

module IPStackControlP {
  provides {
    interface SplitControl;
  }
  uses {
    interface StdControl;
    interface StdControl as RoutingControl;
    interface SplitControl as SubSplitControl;
    interface StdControl as NeighborDiscoveryControl;
    interface IPAddress;
  }
} implementation {

  // Keep track of whether the BLIP stack has been started (using SplitControl)
  bool blip_started = FALSE;

  command error_t SplitControl.start() {
    if (blip_started) return EALREADY;
    return call SubSplitControl.start();
  }

  event void SubSplitControl.startDone(error_t error) {
    if (error == SUCCESS) {
      blip_started = TRUE;
      call StdControl.start();
    }

    call NeighborDiscoveryControl.start();

#if RPL_ADDR_AUTOCONF
    // If we are using the routing layer to get our full address, then
    // we must start the routing layer immediately.
    call RoutingControl.start();
#else
    // Otherwise, check to see if we have a global address before starting
    // the routing layer.
    {
      struct in6_addr addr;
      // if we have a global address, we can start any routing protocols now.
      if (call IPAddress.getGlobalAddr(&addr)) {
        call RoutingControl.start();
      }
    }
#endif

    signal SplitControl.startDone(error);
  }

  command error_t SplitControl.stop() {
    call StdControl.stop();
    call RoutingControl.stop();

    return call SubSplitControl.stop();
  }

  event void SubSplitControl.stopDone(error_t error) {
    if (error == SUCCESS) {
      blip_started = FALSE;
    }
    signal SplitControl.stopDone(error);
  }

  event void IPAddress.changed(bool valid) {
    if (valid) {
      call RoutingControl.start();
    } else {
      call RoutingControl.stop();
    }
  }

 default command error_t StdControl.start() { return SUCCESS; }
 default command error_t StdControl.stop() { return SUCCESS; }
 default command error_t RoutingControl.start() { return SUCCESS; }
 default command error_t RoutingControl.stop() { return SUCCESS; }

}
