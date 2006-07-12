module TelosSerialP {
  provides interface StdControl;
  uses interface Resource;
}
implementation {
  command error_t StdControl.start(){
    return call Resource.immediateRequest();
  }
  command error_t StdControl.stop(){
    call Resource.release();
    return SUCCESS;
  }
  event void Resource.granted(){}
}
