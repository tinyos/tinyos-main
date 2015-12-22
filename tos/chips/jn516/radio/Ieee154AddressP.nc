#include <AM.h>

// TODO HACK 
#ifndef htole16
#define htole16(X)  (X)
#endif

module Ieee154AddressP {
  provides {
    interface Init;
    interface Ieee154Address;
  }
  uses {
    interface LocalIeeeEui64;
  }
} implementation {
  ieee154_saddr_t m_saddr; //in little endian
  ieee154_panid_t m_panid;

  command error_t Init.init() {
    m_saddr = TOS_NODE_ID; //TOS_NODE_ID already little endian. at least on jennic
    m_panid = TOS_AM_GROUP;
    return SUCCESS;
  }

  command ieee154_panid_t Ieee154Address.getPanId() {
    return m_panid;
  }
  command ieee154_saddr_t Ieee154Address.getShortAddr() {
    return m_saddr;
  }
  command ieee154_laddr_t Ieee154Address.getExtAddr() {
    ieee154_laddr_t addr = call LocalIeeeEui64.getId();
    int i;
    uint8_t tmp;
    /* the LocalIeeeEui is big endian */
    /* however, Ieee 802.15.4 addresses are little endian */
    for (i = 0; i < 4; i++) {
      tmp = addr.data[i];
      addr.data[i] = addr.data[7 - i];
      addr.data[7 - i] = tmp;
    }
    return addr;
  }

  command error_t Ieee154Address.setShortAddr(ieee154_saddr_t addr) {
    m_saddr = htole16(addr);
    signal Ieee154Address.changed();
    return SUCCESS;
  }
}
