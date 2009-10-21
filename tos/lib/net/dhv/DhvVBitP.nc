/**
 * DHV Virtual Bits Check Configuration
 *
 * Define interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 **/

#include<Dhv.h>

module DhvVBitP{
  provides interface DhvDecision;

  uses interface DhvSend as VBitSend;
  uses interface DhvReceive as VBitReceive;
  uses interface DhvStateLogic as VBitLogic;
  uses interface DhvLogic as VectorLogic;
  uses interface DhvHelp;	
  uses interface Random;
}

implementation{
  uint8_t commRate;

  command uint8_t DhvDecision.getCommRate()
  {
    return commRate;
  }

  command void DhvDecision.resetCommRate(){
    commRate  = 0;
  }


  /*construct a vector of bits and send it*/
  command error_t DhvDecision.send(){
    uint8_t bindex;
    uint8_t vbit_size;
    uint8_t msg_size;
    uint8_t numMsg;
    uint8_t maxDataLength;
    uint8_t i, j;
    dhv_msg_t* dmsg;
    dhv_vbit_msg_t* dvbmsg;
    uint8_t *versionPtr;
    error_t sendResult;
    uint32_t salt;

    maxDataLength = TOSH_DATA_LENGTH - sizeof(dhv_msg_t) - sizeof(dhv_vbit_msg_t); 
    sendResult = FAIL;

    if(UQCOUNT_DHV != 0)
    {
      vbit_size = ((uint8_t)(UQCOUNT_DHV-1)/VBIT_LENGTH) + 1;
      numMsg    = (vbit_size -1)/maxDataLength + 1;
    }else
    {
      vbit_size = 0;
      numMsg    = 0;
    }

    bindex = call VBitLogic.getVBitIndex();

    //return if 0
    if(bindex  == 0){
      dbg("DhvVBitP", "Error: no vbit to send \n");
    }


    dmsg = call VBitSend.getPayloadPtr();
    if(dmsg == NULL)
      return FAIL;

    dmsg->type = ID_DHV_VBIT;
    dvbmsg = (dhv_vbit_msg_t*) dmsg->content;
    dvbmsg->bindex = bindex;

    //put the hash into the message
    salt = call Random.rand32();
    dvbmsg->info = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);
    dvbmsg->salt = salt;			

    //put the vbit into the message
    versionPtr = call DhvHelp.getVBits(bindex);

    for(j = 0; j < numMsg; j++){//number of tos message_t 
      if(j == numMsg-1){
        //last message
        msg_size = vbit_size - j*maxDataLength;
      }else{
        msg_size = maxDataLength;
      }

      //TODO: need to get this right
      dvbmsg->numKey = msg_size*8;             //number of keys

      for(i = 0; i < msg_size; i++){
        dvbmsg->vindex = j;
        dvbmsg->vbit[i] = versionPtr[j*maxDataLength + i];
        dbg("DhvVBitP", "bindex %d vbit %d:  0x%02x  0x%02x \n",bindex, i, dvbmsg->vbit[i], versionPtr[i]);
      }

      dbg("DhvVBitP", "Sending vbit of index %d size %d \n", bindex, sizeof(dhv_msg_t) + sizeof(dhv_vbit_msg_t) + msg_size );

      for(i = 0; i < msg_size; i++){
        dbg("DhvVBitP", "vbit to send %d, 0x%02x \n", i, dvbmsg->vbit[i]);
      }

      //send the vbit out
      sendResult = call VBitSend.send(sizeof(dhv_msg_t) + sizeof(dhv_vbit_msg_t) + msg_size);
      if(sendResult == SUCCESS){
        //call VBitLogic.unsetVBitIndex(bindex);
        call VBitLogic.setVBitState(0);
        call VBitLogic.unsetHSumStatus();
      }
    }
    return sendResult;	
  }


  event void VBitReceive.receive(void* payload, uint8_t len){
    dhv_vbit_msg_t * rcv_dvbmsg;
    uint8_t bindex, vindex;
    int i,j;
    dhv_version_t version;
    dhv_version_t mask;
    uint8_t diffIndex;
    dhv_key_t diffKey;
    bool isDiff;
    uint8_t vbit_size;
    uint8_t* vbit;
    uint32_t salt, myHash;
    uint8_t maxDataLength;
    uint8_t msg_size;
    uint8_t numMsg;
    uint32_t bitIndexValue;

    isDiff = FALSE;
    commRate = 1;

    maxDataLength = TOSH_DATA_LENGTH - sizeof(dhv_msg_t) - sizeof(dhv_vbit_msg_t);
    if(UQCOUNT_DHV != 0)
    {
      vbit_size = ((uint8_t)(UQCOUNT_DHV-1)/VBIT_LENGTH) + 1;	
      numMsg = (vbit_size -1)/maxDataLength + 1;

    }else
    {
      vbit_size = 0;
      numMsg    = 0;	
    }

    rcv_dvbmsg = (dhv_vbit_msg_t*) payload;
    bindex = rcv_dvbmsg->bindex;
    vindex = rcv_dvbmsg->vindex;

    dbg("DhvVBitP", "Receive vbit of index %d numMsg %d vbit_size %d \n", bindex, numMsg, vbit_size );

    //compare the hash first
    salt = rcv_dvbmsg->salt;
    myHash = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);

    if(myHash == rcv_dvbmsg->info){
      //some duplicates
      dbg("DhvVBitP", "same summary\n");
      call VBitLogic.setSameSummary();

    }else{
      vbit = call DhvHelp.getVBits(bindex);	
      if(vindex == numMsg-1){
        msg_size = vbit_size - vindex*maxDataLength;
        //dbg("DhvVBitP", "Last message vindex %d  numMsg %d msg_size %d \n", vindex, numMsg, msg_size );
      }else{
        msg_size = maxDataLength;
        //dbg("DhvVBitP", "Not last message %d\n", msg_size);
      }

      //compare with the rcv vbits
      for(i = 0; i < msg_size; i++){
        dbg("DhvVBitP", "numMsg %d bindex %d vbit %d vindex %d: msg_size %d  local 0x%02x -  rcv  0x%02x \n",numMsg, bindex, i, vindex, msg_size ,vbit[vindex*maxDataLength+i],rcv_dvbmsg->vbit[i]);
        if(vbit[vindex*maxDataLength + i] != rcv_dvbmsg->vbit[i]){
          version = rcv_dvbmsg->vbit[i]^vbit[vindex*maxDataLength + i];
          mask = 1;
          if(version != 0){
            dbg("DhvVBitP", "There is a difference \n");
            isDiff = TRUE;
            for(j = 0; j < VBIT_LENGTH; j++){
              if((version & mask) != 0){
                diffIndex = (VBIT_LENGTH -j) + VBIT_LENGTH*i + vindex*maxDataLength - 1 ;
                dbg("DhvVBitP", "Detect difference at %d, %d %d  %d %d \n", diffIndex, i, j, vindex, maxDataLength);								

                diffKey = call DhvHelp.indexToKey(diffIndex);
                call VectorLogic.setItem(diffKey);
              }
              mask = mask << 1;
            }
          } 
        }
      }

      //reset this bit
      call VBitLogic.unsetVBitIndex(bindex);

      if((isDiff == FALSE)){
        bitIndexValue = call VBitLogic.getVBitState();
        if(bitIndexValue == 0){
          //tell DhvLogic to send the next bindex
          bindex++;
          dbg("DhvVBitP", "No Difference detected, move to bindex %d \n", bindex );
          call VBitLogic.setVBitIndex(bindex);						
        }
      }else{
        dbg("DhvVBitP","difference detected, reset to 0 \n");
      }	
    }	
  }
}
