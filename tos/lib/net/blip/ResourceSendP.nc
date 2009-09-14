
#include <Ieee154.h>

#include "PrintfUART.h"

module ResourceSendP {
  provides interface Ieee154Send;
  uses interface Resource;
  uses interface Ieee154Send as SubSend;
} implementation {
  ieee154_saddr_t m_addr;
  message_t      *m_msg = NULL;
  uint8_t         m_len;
  
  command error_t Ieee154Send.send(ieee154_saddr_t addr,
                                   message_t* msg,
                                   uint8_t len) {
    if (m_msg != NULL) return EBUSY;

    m_addr = addr;
    m_msg = msg;
    m_len = len;

    call Resource.request();
    return SUCCESS;
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    call Resource.release();
    signal Ieee154Send.sendDone(msg, result);
    m_msg = NULL;
  }

  event void Resource.granted() {
    error_t rc;
    if ((rc = (call SubSend.send(m_addr, m_msg, m_len))) != SUCCESS) {
      signal Ieee154Send.sendDone(m_msg, rc);
      m_msg = NULL;
      call Resource.release();
    }
  }

  command error_t Ieee154Send.cancel(message_t* msg) {
    if (m_msg != NULL) {
      call Resource.release();
      m_msg = NULL;
      return call SubSend.cancel(msg);
    } else {
      return FAIL;
    }
  }

  command uint8_t Ieee154Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void* Ieee154Send.getPayload(message_t* m, uint8_t len) {
    return call SubSend.getPayload(m, len);
  }


}
