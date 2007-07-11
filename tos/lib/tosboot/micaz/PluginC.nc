
module PluginC {
  provides {
    interface StdControl;
  }
}

implementation {

  command error_t StdControl.start() { return SUCCESS; }
  command error_t StdControl.stop() { return SUCCESS; }

}
