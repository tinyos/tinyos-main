/**
 * DHV Summary Message Implementation.
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

module DhvSummaryP {
  provides interface DhvDecision;

  uses interface DhvSend as SummarySend;
  uses interface DhvReceive as SummaryReceive;
  uses interface DhvHelp;
  uses interface Random;
	uses interface DhvStateLogic as StateLogic;
}

implementation {
  uint32_t computeHash(dhv_index_t left, dhv_index_t right,
		       dhv_version_t* basedata, uint32_t salt);
  uint8_t commRate;

  command uint8_t DhvDecision.getCommRate() {
    return commRate;
  }

  command void DhvDecision.resetCommRate() {
    commRate = 0;
  }

  command error_t DhvDecision.send() {
    uint32_t salt;
    dhv_msg_t* dmsg;
    dhv_summary_msg_t* dsmsg;

    dmsg = (dhv_msg_t*) call SummarySend.getPayloadPtr();
    if(dmsg == NULL)
        return FAIL;

    dmsg->type = ID_DHV_SUMMARY;
    dsmsg = (dhv_summary_msg_t*) dmsg->content;

    salt = call Random.rand32();
    dsmsg->info = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);
    dsmsg->salt = salt;

    dbg("DhvSummaryP", "Hash Entry: %08x \n",	 dsmsg->info);
    return call SummarySend.send(sizeof(dhv_msg_t) + sizeof(dhv_summary_msg_t));
  }

  event void SummaryReceive.receive(void* payload, uint8_t len) {
    dhv_summary_msg_t* dsmsg;
    uint32_t salt, myHash;


    dsmsg = (dhv_summary_msg_t*) payload;
    salt = dsmsg->salt;
    
    myHash = call DhvHelp.computeHash(0, UQCOUNT_DHV, salt);
    if(myHash != dsmsg->info) {
				//call StateLogic.setDiffSummary();
				call StateLogic.setHSumStatus();
        dbg("DhvSummaryP", "Hashes don't match\n");
    }
      else {
				call StateLogic.setSameSummary();
        commRate = commRate + 1;
        dbg("DhvSummaryP", "Hashes match\n");
    }
  }
}
