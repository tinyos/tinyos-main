/**
 * DHV Vector Message Configuration
 *
 * Define interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

#include <Dhv.h>

module DhvVectorP {
  provides interface DhvDecision;

  uses interface DhvSend as VectorSend;
  uses interface DhvReceive as VectorReceive;
  uses interface DhvLogic as VectorLogic;
  uses interface DhvLogic as DataLogic;
  uses interface DhvHelp;
  uses interface Random;
}

implementation {
  uint8_t commRate = 0;

  int myComparator(const void* a, const void* b);

  command uint8_t DhvDecision.getCommRate() {
    return commRate;
  }

  command void DhvDecision.resetCommRate() {
    commRate = 0;
  }

  command error_t DhvDecision.send() {
    dhv_index_t i, j;
    dhv_key_t sendkey;
    bool* keyvector;
    dhv_msg_t* dmsg;
    dhv_vector_msg_t* dvmsg;
    error_t status;

    dbg("DhvVectorP", "prepare to send vector out \n");

    dmsg = call VectorSend.getPayloadPtr();
    if(dmsg == NULL) {
      return FAIL;
    }

    keyvector = call VectorLogic.allItem();
    dmsg->type = ID_DHV_VECTOR;
    dvmsg = (dhv_vector_msg_t*) dmsg->content;

    //dvmsg->unitLen = DHV_VECTOR_ENTRIES_PER_PACKET;

    //TODO: need to check for concurrency in here
    i = 0;
    for(j = 0; j < UQCOUNT_DHV; j++){
      if(keyvector[j] > ID_DHV_NO){
        sendkey = call DhvHelp.indexToKey(j);

        /*if(keyvector[j] == ID_DHV_REQ){
          dbg("DhvVectorP", " keyvector %d == %d \n", keyvector[j], ID_DHV_REQ);
          dmsg->type = ID_DHV_VECTOR_REQ;
          }*/

        if(i < DHV_VECTOR_ENTRIES_PER_PACKET) {
          dvmsg->vector[i] = sendkey;
          dvmsg->vector[i+1] = call DhvHelp.keyToVersion(sendkey);
          dbg("DhvVectorP","diff vector 0x%08x  0x%08x %d %d \n",dvmsg->vector[i] ,  dvmsg->vector[i+1], j, keyvector[j]);
          i = i + 2;
        }else{ break; }		
      }
    }

    dvmsg->unitLen = i;

    //TODO: need to fix
    //	dbg("DhvVectorP", "Sending vector message out ...unitLen 0x%02x \n", dvmsg->unitLen);
    status = call VectorSend.send(sizeof(dhv_msg_t) + sizeof(dhv_vector_msg_t) +
        (i*sizeof(uint32_t)));

    i = 0;
    dbg("DhvVectorP","Send status %d vs FALSE %d \n", status, FALSE);

    if(status == SUCCESS){dbg("DhvVectorP","status == SUCCESS\n");}
    if(status == FAIL){dbg("DhvVectorP","status == FAIL\n");}

    //TODO: need to check for actual send status here 
    if(TRUE)
    {
      dbg("DhvVectorP", "Send msg successfully \n");			
      for(j = 0; j < UQCOUNT_DHV; j++){
        if(keyvector[j] > ID_DHV_NO){
          sendkey = call DhvHelp.indexToKey(j);
          if(i < DHV_VECTOR_ENTRIES_PER_PACKET) {
            call VectorLogic.unsetItem(sendkey);
            i = i + 2;
          }else{
            break;
          }			
        }
      }
    }

    dbg("DhvVectorP", "Sent vector message out ...unitLen %d \n", dvmsg->unitLen);
    return SUCCESS;	
  }

  /*TODO: a callback event to remove the sent vectors*/
  event void VectorReceive.receive(void* payload, uint8_t len) {
    dhv_vector_msg_t* dvmsg;
    dhv_msg_t* dmsg;

    uint8_t unitlen;
    uint8_t i;
    uint8_t type;
    uint32_t vectorkey;
    uint32_t vectorver;
    uint32_t myver;

    commRate  = commRate + 1;        	
    dmsg  = (dhv_msg_t*) payload; 
    type = dmsg->type;

    dvmsg = (dhv_vector_msg_t*) dmsg->content;
    unitlen = dvmsg->unitLen;

    dbg("DhvVectorP", "Receive vector msg len %u  unitlen 0x%02x  0x%02x \n", len, unitlen, dvmsg->unitLen);			

    for(i = 0; i < unitlen; i += 2) {
      vectorkey = dvmsg->vector[i];
      vectorver = dvmsg->vector[i+1];
      myver = call DhvHelp.keyToVersion(vectorkey);
      dbg("DhvVectorP", "key 0x%08x  version 0x%08x myver 0x%08x \n", vectorkey, vectorver, myver);
      // TODO: handle the invalid versions

      if(myver < vectorver) {
        dbg("DhvVectorP", "I have an older version -> setItem \n");
        call VectorLogic.setItem(vectorkey);
      }
      else if(myver > vectorver) {
        dbg("DhvVectorP", "I have a newer version -> Data.setItem \n");
        call DataLogic.setItem(vectorkey);
      }
      else{
        dbg("DhvVectorP", "Request msg and I have the same version -> keep quite \n");
        call VectorLogic.unsetItem(vectorkey);					
      }
    }
  }
}
