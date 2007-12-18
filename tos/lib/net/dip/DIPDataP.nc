
#include <DIP.h>

module DIPDataP {
  provides interface DIPDecision;

  uses interface DIPSend as DataSend;
  uses interface DIPReceive as DataReceive;

  uses interface DisseminationUpdate<dip_data_t>[dip_key_t key];
  uses interface DisseminationValue<dip_data_t>[dip_key_t key];

  uses interface DIPHelp;
  uses interface DIPEstimates;

  uses interface Leds;
}

implementation {
  uint8_t commRate = 0;

  command uint8_t DIPDecision.getCommRate() {
    return commRate;
  }

  command void DIPDecision.resetCommRate() {
    commRate = 0;
  }

  command error_t DIPDecision.send() {
    // Scan all estimates and send the highest estimate in deterministic order
    dip_index_t i;
    dip_index_t high_i;
    dip_index_t high_est;
    dip_key_t key;
    dip_version_t ver;
    dip_estimate_t* ests;
    dip_msg_t* dmsg;
    dip_data_msg_t* ddmsg;
    const dip_data_t* data;

    ests = call DIPEstimates.getEstimates();
    high_i = 0;
    high_est = 0;
    for(i = 0; i < UQCOUNT_DIP; i++) {
      if(ests[i] > high_est) {
	high_i = i;
	high_est = ests[i];
      }
    }
    key = call DIPHelp.indexToKey(high_i);
    ver = call DIPHelp.keyToVersion(key);
    data = call DisseminationValue.get[key]();
    dmsg = (dip_msg_t*) call DataSend.getPayloadPtr();
    if(dmsg == NULL) {
      return FAIL;
    }
    ddmsg = (dip_data_msg_t*) dmsg->content;
    dmsg->type = ID_DIP_DATA;

    ddmsg->key = key;
    ddmsg->version = ver;
    ddmsg->size = sizeof(dip_data_t);
    memcpy(ddmsg->data, data, sizeof(dip_data_t));

    call DIPEstimates.decEstimateByKey(key);
    dbg("DIPDataP", "Data sent with key %x and version %08x\n", key, ver);
    return call DataSend.send(sizeof(dip_data_msg_t) + sizeof(dip_msg_t) + sizeof(dip_data_t));
  }
  
  event void DataReceive.receive(void* payload, uint8_t len) {
    dip_key_t key;
    dip_version_t myVer;
    dip_version_t msgVer;
    dip_data_msg_t* ddmsg;

    commRate = commRate + 1;

    ddmsg = (dip_data_msg_t*) payload;
    key = ddmsg->key;
    msgVer = ddmsg->version;
    myVer = call DIPHelp.keyToVersion(key);
    dbg("DIPDataP", "Data rcved with key %x and version %08x\n", key, msgVer);

    // TODO: handle the invalid versions
    if(myVer < msgVer) {
      call DisseminationUpdate.change[key]((dip_data_t*)ddmsg->data);
      call DIPHelp.setVersion(key, msgVer);
      call DIPEstimates.setDataEstimate(key);
    }
    else if (myVer > msgVer) {
      call DIPEstimates.setDataEstimate(key);
    }
    else {
      call DIPEstimates.decEstimateByKey(key);
    }
  }
  
  event void DisseminationValue.changed[dip_key_t key]() {  }
  
 default command const dip_data_t* DisseminationValue.get[dip_key_t key]() {
   return NULL;
 }

 default command void DisseminationUpdate.change[dip_key_t key](dip_data_t* val) { }
  
}
