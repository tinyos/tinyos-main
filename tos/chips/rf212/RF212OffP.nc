#include "RF212DriverLayer.h"
#include "RadioConfig.h"
module RF212OffP {
  provides interface Init;
  uses interface Resource as SpiResource;
  uses interface FastSpiByte;  
  uses interface GeneralIO as SELN;
  uses interface GeneralIO as SLP_TR;
  uses interface GeneralIO as RSTN;
  uses interface BusyWait<TMicro, uint16_t>;
}
implementation {
  
  inline void writeRegister(uint8_t reg, uint8_t value)
  {
    call SELN.clr();
    call FastSpiByte.splitWrite(RF212_CMD_REGISTER_WRITE | reg);
    call FastSpiByte.splitReadWrite(value);
    call FastSpiByte.splitRead();
    call SELN.set();
  }
  
  inline  void initRadio()
  {
    call BusyWait.wait(510);

    call SELN.makeOutput();
    call RSTN.makeOutput();
    call SLP_TR.makeOutput();
    call SELN.set();
    call RSTN.clr();
    call SLP_TR.clr();
    call BusyWait.wait(6);
    call RSTN.set();
    //reset done
    
    writeRegister(RF212_TRX_CTRL_0, RF212_TRX_CTRL_0_VALUE);
    writeRegister(RF212_TRX_STATE, RF212_TRX_OFF);
    call SpiResource.release();
    
    call BusyWait.wait(510);
    //TRX_OFF state
    call SLP_TR.set();
    //sleep
  }

  
  command error_t Init.init() {
    if(!uniqueCount("RF212RadioOn")) {
      if(call SpiResource.immediateRequest() == SUCCESS){
        initRadio();
      } else
        call SpiResource.request();
    }
    return SUCCESS;
  }
  
  event void SpiResource.granted(){
    if(!uniqueCount("RF212RadioOn")) {
      initRadio();
    }
  }
}