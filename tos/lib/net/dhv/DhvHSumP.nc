/**
 * DHV Horizontal Summary Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 **/

#include<Dhv.h>

module DhvHSumP{
  provides interface DhvDecision;

  uses interface DhvSend as HSumSend;
  uses interface DhvReceive as HSumReceive;
  uses interface DhvStateLogic as VBitLogic;
  uses interface DhvHelp;
  uses interface Random;	
}

implementation{
  uint8_t commRate;

  command uint8_t DhvDecision.getCommRate(){
    return commRate;
  }
  command void DhvDecision.resetCommRate(){
    commRate = 0;
  }
  command error_t DhvDecision.send(){
    dhv_hsum_msg_t* dhsmsg;
    dhv_msg_t* 			dmsg;
    uint32_t  salt;
    error_t sendResult;

    dmsg = call HSumSend.getPayloadPtr();
    if(dmsg == NULL)
        return FAIL;

    dmsg->type = ID_DHV_HSUM;
    dhsmsg = (dhv_hsum_msg_t*) dmsg->content;

    //add the hash value
    salt = call Random.rand32();
    dhsmsg->info = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);
    dhsmsg->salt = salt;
    dhsmsg->checksum = call DhvHelp.getHSum();

    sendResult = call HSumSend.send(sizeof(dhv_msg_t) + sizeof(dhv_hsum_msg_t));
    if(sendResult == SUCCESS){
      call VBitLogic.unsetHSumStatus();
    }
    return sendResult;
  }	

  event void HSumReceive.receive(void* payload, uint8_t len){
    dhv_hsum_msg_t * rcv_dhmsg;
    int32_t local_checksum;
    int32_t rcv_checksum;
    int32_t xor_checksum;
    int32_t salt;
    int32_t rcv_hash;
    int32_t local_hash;

    rcv_dhmsg = (dhv_hsum_msg_t*) payload;

    rcv_checksum = rcv_dhmsg->checksum;
    local_checksum = call DhvHelp.getHSum();
    xor_checksum = rcv_checksum^local_checksum;
    dbg("DhvHSumP", " xor_checksum 0x%08x  0x%08x  0x%08x \n",rcv_checksum, local_checksum, xor_checksum);
    if(xor_checksum == 0){
      //check for the hash
      rcv_hash = rcv_dhmsg->info;
      salt = rcv_dhmsg->salt;
      local_hash = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);
      if(rcv_hash == local_hash) {
        call VBitLogic.setSameSummary();
        commRate = commRate + 1;
      }else{
        call VBitLogic.setVBitState(1);
      }
    }else{
      dbg("DhvHSumP"," detect a difference in checksum \n" );
      call VBitLogic.setVBitState(xor_checksum);
    }
  }
}
