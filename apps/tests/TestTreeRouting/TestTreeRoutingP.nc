module TestTreeRoutingP {
    uses interface Boot;
    uses interface Init;
    uses interface StdControl as TreeControl;
    uses interface SplitControl as RadioControl;
    uses interface RootControl;
    uses interface Timer;
}
implementation {
    event void Boot.booted() {
        call Init.init();
        call RadioControl.start();
        call TreeControl.start();
        if (TOS_NODE_ID == 0 || TOS_NODE_ID == 173) {
            call RootControl.setRoot();
        }

    }

    event void RadioControl.startDone(error_t error) {
    }
  
    event void RadioControl.stopDone(error_t error) {
    }
}
