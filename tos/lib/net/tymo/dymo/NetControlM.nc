/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

/**
 * NetControlM - Manages the control of all components involved in the
 * DymoNetwork component.
 *
 * @author Romain Thouvenin
 */

// TODO generalize to a multiControl
module NetControlM {
  provides interface SplitControl;
  uses {
    interface SplitControl as AMControl;
    interface StdControl   as TableControl;
    interface SplitControl as EngineControl;
  }
}

implementation {
  uint8_t started;

  command error_t SplitControl.start(){
    error_t e = call TableControl.start();
    started = 1;

    if(e == SUCCESS){

      e = call AMControl.start();
      if(e == SUCCESS)
	return call EngineControl.start();
      else
	return e;
      
    } else {
      return e;
    }
  }

  event void AMControl.startDone(error_t e){
    if (e == SUCCESS) {
      if (started++ == 2)
	signal SplitControl.startDone(e);
    } else if (started) {
      started = 0;
      signal SplitControl.startDone(e);
    }
  }

  event void EngineControl.startDone(error_t e) {
    if (e == SUCCESS) {
      if (started++ == 2)
	signal SplitControl.startDone(e);
    } else if (started) {
      started = 0;
      signal SplitControl.startDone(e);
    }
  }

  command error_t SplitControl.stop(){
    if(call AMControl.stop() == SUCCESS)
      return call TableControl.stop();
    else
      return FAIL;
  }

  event void AMControl.stopDone(error_t e){
    signal SplitControl.stopDone(e);
  }

  event void EngineControl.stopDone(error_t e){ }

}
