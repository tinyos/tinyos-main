module Stm25pPowerP{
  provides interface Init;
  uses interface GeneralIO as Power;  
  #ifndef STM25P_HW_POWER_DISABLE
  provides interface SplitControl;
  uses interface SplitControl as SpiControl;
  uses interface Timer<TMilli>;
  #endif
}
implementation{
#ifdef STM25P_HW_POWER_DISABLE
  
  command error_t Init.init(){
    call Power.makeOutput();
    call Power.clr();
    return SUCCESS;
  }
  
#else

  bool spiOn=FALSE;
  bool powerOn=TRUE;
  
  command error_t Init.init(){
    call Power.makeOutput();
    call Power.set();
    powerOn=FALSE;
    return SUCCESS;
  }
  
  command error_t SplitControl.start(){
    error_t err;
    if(spiOn&&powerOn)
      return EALREADY;
    else if(spiOn||powerOn)
      return EBUSY;
    err=call SpiControl.start();
    if(err==SUCCESS){
      call Power.clr();
      call Timer.startOneShot(10);
      return SUCCESS;
    } else
      return err;
  }
  
  event void Timer.fired(){
    powerOn=TRUE;
    if(spiOn)
      signal SplitControl.startDone(SUCCESS);
  }
  
  event void SpiControl.startDone(error_t err){
    if(err==SUCCESS){
      spiOn=TRUE;
      if(powerOn)
        signal SplitControl.startDone(SUCCESS);
    } else {
      if(!powerOn)
        call Timer.stop();
      call Power.set();
      signal SplitControl.startDone(err);
    }
  }
  
  task void signalStopDone(){
    signal SplitControl.stopDone(SUCCESS);
  }
  
  command error_t SplitControl.stop(){
    if((!spiOn)&&(!powerOn))
      return EALREADY;
    else if((!spiOn)||(!powerOn))
      return EBUSY;
    return call SpiControl.stop();
  }
  
  event void SpiControl.stopDone(error_t err){
    if(err==SUCCESS){
      spiOn=FALSE;
      call Power.set();
      powerOn=FALSE;
      signal SplitControl.startDone(SUCCESS);
    } else {
      signal SplitControl.startDone(err);
    }
  }
#endif
}