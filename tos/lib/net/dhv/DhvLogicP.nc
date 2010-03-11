/**
 * DHV Logic Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

#include <Dhv.h>

module DhvLogicP {
  provides interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];

  provides interface Init;
  provides interface StdControl;
  provides interface DhvLogic as VectorLogic;
  provides interface DhvLogic as DataLogic;
  provides interface DhvStateLogic;	

  uses interface Boot;
  uses interface DhvTrickleTimer;
  uses interface DisseminationUpdate<dhv_data_t> as VersionUpdate[dhv_key_t key];

  uses interface DhvDecision as DhvDataDecision;
  uses interface DhvDecision as DhvVectorDecision;
  uses interface DhvDecision as DhvSummaryDecision;
  uses interface DhvDecision as DhvVBitDecision;
  uses interface DhvDecision as DhvHSumDecision;

  uses interface DhvCache as DhvDataCache;
  uses interface DhvCache as DhvVectorCache;
  uses interface DhvHelp;

}

implementation {
  uint32_t windowSize;
  uint8_t sendDecision();
  uint32_t bitIndex;
  uint8_t hsum_status;
  uint32_t diffHash;

  command error_t Init.init() {
    windowSize = DHV_TAU_LOW;
    dbg("DhvLogicP","DHV ready\n");
    return SUCCESS;
  }

  event void Boot.booted() {
    hsum_status = 0;
    bitIndex = 0;
  }

  command error_t StdControl.start() {
    return call DhvTrickleTimer.start();
  }

  command error_t StdControl.stop() {
    call DhvTrickleTimer.stop();
    return SUCCESS;
  }


  /*Logic operation on the vector */	
  command error_t VectorLogic.setItem(dhv_key_t key){
    call DhvVectorCache.addItem(key);
    call DhvTrickleTimer.reset();
    return SUCCESS;
  }

  command error_t VectorLogic.setReqItem(dhv_key_t key){
    call DhvVectorCache.addReqItem(key);
    call DhvTrickleTimer.reset();
    return SUCCESS;
  }

  command error_t VectorLogic.unsetItem(dhv_key_t key){
    call DhvVectorCache.removeItem(key);
    call DhvStateLogic.setVBitState(0);
    return SUCCESS;
  }

  command uint8_t * VectorLogic.allItem(){
    return call DhvVectorCache.allItem();
  }

  command uint8_t VectorLogic.nextItem(){
    return call DhvVectorCache.nextItem();
  }

  /*logic operations on the data*/
  command error_t DataLogic.setItem(dhv_key_t key){
    call DhvDataCache.addItem( key);
    call DhvTrickleTimer.reset();
    return SUCCESS;
  }

  command error_t DataLogic.setReqItem(dhv_key_t key){
    call DhvDataCache.addReqItem( key);
    call DhvTrickleTimer.reset();
    return SUCCESS;
  }

  command error_t  DataLogic.unsetItem(dhv_key_t key){
    call DhvDataCache.removeItem(key);
    call DhvStateLogic.setVBitState(0);
    return SUCCESS;
  }

  command uint8_t* DataLogic.allItem(){
    return call DhvDataCache.allItem();
  }

  command uint8_t DataLogic.nextItem(){
    return call DhvDataCache.nextItem();
  }

  /*logic operation for the summary and vbit*/
  command void DhvStateLogic.setHSumStatus(){
    hsum_status = 1;
    call	DhvTrickleTimer.reset();
  }

  command void DhvStateLogic.unsetHSumStatus(){
    hsum_status = 0;
  }

  command uint8_t DhvStateLogic.getHSumStatus(){
    return hsum_status;
  }

  command void DhvStateLogic.setDiffSummary(){
    if(bitIndex == 0){
      bitIndex=1;
    }

    call	DhvTrickleTimer.reset();
  }

  command void DhvStateLogic.setSameSummary(){
    bitIndex = 0;
    hsum_status = 0;
    //reset all the vector and data status to avoid flooding
    call DhvDataCache.removeAll();
    call DhvVectorCache.removeAll();

  }	

  command void DhvStateLogic.setVBitState(uint32_t state){
    bitIndex = state;
    if(state != 0){
      call	DhvTrickleTimer.reset();
    }
  }

  command uint32_t DhvStateLogic.getVBitState(){
    return bitIndex;
  }

  //unset one bit at index location
  command void DhvStateLogic.unsetVBitIndex(uint8_t dindex){
    uint32_t mask;
    mask = 1;

    mask = mask << (dindex-1);
    dbg("TempDebug", "TempDebug: Before mask dindex bitIndex %d %d %d\n", mask, dindex, bitIndex);
    if((bitIndex & mask) != 0){
      bitIndex = bitIndex^mask;
    }
    dbg("TempDebug", "TempDebug: After bitIndex %d\n", bitIndex); 
  }

  command void DhvStateLogic.setVBitIndex(uint8_t dindex){
    uint32_t mask;
    mask = 1;
    mask = mask << (dindex-1);

    bitIndex = bitIndex | mask;

    call	DhvTrickleTimer.reset();
  }

  //get the non-zero bit index to extract the vertical bits.
  command uint8_t DhvStateLogic.getVBitIndex(){

    uint32_t mask;
    uint8_t i;
    uint32_t xor;

    if(bitIndex == 0){
      return 0;
    }else
    {
      mask = 1;
      for(i = 1; i <= 32; i++){
        xor = bitIndex & mask;

        dbg("TempDebug", "TempDebug: %d  %d  %d  %d \n", i, bitIndex, mask, xor);
        if(xor != 0){
          return i;
        }
        mask = mask << 1;			
      }
      return 0;
    }
  }



  command void DisseminationUpdate.change[dhv_key_t key](dhv_data_t* val) {

    dbg("DhvLogicP","App notified key %x is new\n", key);

    //update data: actual reprogramming job
    call VersionUpdate.change[key](val);

    //set data
    call DhvDataCache.addItem(key);

    //set to advertise its version
    call DhvVectorCache.addItem(key);

    //reset bindex
    call DhvStateLogic.setVBitState(0);	

    dbg("DhvLogicP","Reset bindex to 0\n");
    //reset timer		  
    call DhvTrickleTimer.reset();
  }

  event uint32_t DhvTrickleTimer.requestWindowSize() {
    //TODO: consider if this is neccessary
    uint8_t decision;

    decision =  sendDecision();

    if(decision == ID_DHV_SUMMARY){
      windowSize = windowSize << 1;
      if(windowSize > DHV_TAU_HIGH){
        windowSize = DHV_TAU_HIGH;
      }
    }else{
      if(decision != ID_DHV_INVALID){
        windowSize = DHV_TAU_LOW;
      }
    }

    dbg("DhvLogicP", "Time window size requested, give %u : send decision %d \n", windowSize, decision);
    return windowSize;
  }

  event void DhvTrickleTimer.fired() {
    uint8_t decision;

    dbg("DhvLogicP","Trickle Timer fired!\n");

    decision = sendDecision();

    switch(decision) {
      case ID_DHV_INVALID:
        dbg("DhvLogicP", "Decision to SUPPRESS\n");
        break;
      case ID_DHV_SUMMARY:
        dbg("DhvLogicP", "Decision to SUMMARY\n");
        call DhvSummaryDecision.send();
        break;
      case ID_DHV_VECTOR:
        dbg("DhvLogicP", "Decision to VECTOR\n");
        call DhvVectorDecision.send();
        break;
      case ID_DHV_DATA:
        dbg("DhvLogicP", "Decision to DATA\n");
        call DhvDataDecision.send();
        break;
      case ID_DHV_VBIT:
        dbg("DhvLogicP", "Decision to VSUM\n");
        call DhvVBitDecision.send();
        break;
      case ID_DHV_HSUM:
        dbg("DhvLogicP", "Decision to HSUM\n");
        call DhvHSumDecision.send();
        break;
    }
    call DhvDataDecision.resetCommRate();
    call DhvVectorDecision.resetCommRate();
    call DhvSummaryDecision.resetCommRate();
    call DhvVBitDecision.resetCommRate();
    call DhvHSumDecision.resetCommRate();

    //set bitstate to zero
    call DhvStateLogic.setVBitState(0);	
  }

  uint8_t sendDecision() {

    bool hasItemToSend;
    uint32_t bindex;
    uint8_t dataCommRate;
    uint8_t vectorCommRate;
    uint8_t summaryCommRate;
    uint8_t vbitCommRate;
    uint8_t hsumCommRate;

    dataCommRate = call DhvDataDecision.getCommRate();
    vectorCommRate = call DhvVectorDecision.getCommRate();
    summaryCommRate = call DhvSummaryDecision.getCommRate();
    vbitCommRate    = call DhvVBitDecision.getCommRate();
    hsumCommRate    = call DhvHSumDecision.getCommRate();

    if(dataCommRate > INFO_THRESHOLD){
      return ID_DHV_INVALID;  
    }

    hasItemToSend = FALSE;
    hasItemToSend = call DhvDataCache.hasItemToSend();
    if(hasItemToSend){
      dbg("DhvLogicP", "has data to send? %u \n", hasItemToSend);
      return ID_DHV_DATA;
    }

    // didn't send or hear data at this point
    if(dataCommRate + vectorCommRate + summaryCommRate + vbitCommRate + hsumCommRate >= INFO_THRESHOLD) {
      dbg("DhvLogicP", "Heard an advertisement\n");
      return ID_DHV_INVALID;
    }

    hasItemToSend = call DhvVectorCache.hasItemToSend();
    dbg("DhvLogicP", "has vector to send? %u \n", hasItemToSend);

    if(hasItemToSend){
      return ID_DHV_VECTOR;
    }

    bindex = call DhvStateLogic.getVBitState();
    dbg("DhvLogicP", "send decision bindex %d \n", bindex);		

    if(bindex != 0){
      return ID_DHV_VBIT;
    }

    if(hsum_status != 0){
      return ID_DHV_HSUM;
    }

    return ID_DHV_SUMMARY;		
  }
}
