
module Ieee154AddressP {
  provides {
    interface Init;
    interface Ieee154Address;
  }
  uses {
    interface LocalIeeeEui64;
    interface CC2420Config;
  }
} implementation {
  ieee154_saddr_t m_saddr;
  ieee154_panid_t m_panid;

  command error_t Init.init() {
    m_saddr = TOS_NODE_ID;
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
    m_saddr = addr;
    call CC2420Config.setShortAddr(addr);
    call CC2420Config.sync();
    signal Ieee154Address.changed();
    return SUCCESS;
  }

  event void CC2420Config.syncDone(error_t err) {}
}
