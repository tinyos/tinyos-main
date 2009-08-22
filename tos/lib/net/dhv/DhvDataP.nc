/**
 * DHV DATA Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 * @modified 8/28/2008  Took the source code from DIP.
 **/


#include <Dhv.h>

module DhvDataP {
  provides interface DhvDecision;

  uses interface DhvSend as DataSend;
  uses interface DhvReceive as DataReceive;

  uses interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];
  uses interface DisseminationValue<dhv_data_t>[dhv_key_t key];
  uses interface DhvLogic as DataLogic;
  uses interface DhvLogic as VectorLogic;

  uses interface DhvHelp;
  uses interface Leds;
}

implementation {
  uint8_t commRate = 0;

  command uint8_t DhvDecision.getCommRate() {
    return commRate;
  }

  command void DhvDecision.resetCommRate() {
    commRate = 0;
  }

  command error_t DhvDecision.send() {
    dhv_key_t key;
    uint8_t i;
    dhv_version_t ver;
    dhv_msg_t* dmsg;
    dhv_data_msg_t* ddmsg;
    const dhv_data_t* data;
    error_t status;

    status = FAIL;
    //get the associated key of the data needed to send
    i = call DataLogic.nextItem();
    if(i == UQCOUNT_DHV){
      return FAIL;
    }
    key = call DhvHelp.indexToKey(i);
    ver = call DhvHelp.keyToVersion(key);
    data = call DisseminationValue.get[key]();
    dmsg = (dhv_msg_t*) call DataSend.getPayloadPtr();
    if(dmsg == NULL) {
      return FAIL;
    }
    ddmsg = (dhv_data_msg_t*) dmsg->content;
    dmsg->type = ID_DHV_DATA;
    ddmsg->key = key;
    ddmsg->version = ver;
    ddmsg->size = sizeof(dhv_data_t);
    memcpy(ddmsg->data, data, sizeof(dhv_data_t));

    dbg("DhvDataP", "Data sent with index %d key %x and version %08x\n",i, key, ver);
    status = call DataSend.send(sizeof(dhv_data_msg_t) + sizeof(dhv_msg_t) + sizeof(dhv_data_t));
    if(status == SUCCESS){
      call DataLogic.unsetItem(key);
    }

    return status;
  }

  event void DataReceive.receive(void* payload, uint8_t len) {
    dhv_key_t key;
    dhv_version_t myVer;
    dhv_version_t msgVer;
    dhv_data_msg_t* ddmsg;

    commRate = commRate + 1;
    ddmsg = (dhv_data_msg_t*) payload;
    key = ddmsg->key;
    msgVer = ddmsg->version;
    myVer = call DhvHelp.keyToVersion(key);
    dbg("DhvDataP", "Data rcved with key %x and version %08x\n", key, msgVer);

    // TODO: handle the invalid versions
    if(myVer < msgVer) {
      dbg("DhvDataP", "new version\n");
      call DisseminationUpdate.change[key]((dhv_data_t*)ddmsg->data);
      call DhvHelp.setVersion(key, msgVer);
      call DataLogic.setItem(key);
      call VectorLogic.setItem(key);
      //set bindex to 0
    }
    else if (myVer > msgVer) {
      dbg("DhvDataP", "Old version\n");
      //report older key to dhvlogic to set data item to send
      //reset timer
      call DataLogic.setItem(key);
      call VectorLogic.setItem(key);

    }
    else {
      dbg("DhvDataP", "Same version\n");
      //keep quite
      call DataLogic.unsetItem(key);
      call VectorLogic.unsetItem(key);
      //set bindex to 0
    }
  }

  event void DisseminationValue.changed[dhv_key_t key]() {  }

  default command const dhv_data_t* DisseminationValue.get[dhv_key_t key]() {
    return NULL;
  }

  default command void DisseminationUpdate.change[dhv_key_t key](dhv_data_t* val) { }

}
