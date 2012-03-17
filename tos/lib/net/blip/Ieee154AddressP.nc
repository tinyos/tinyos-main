
module Ieee154AddressP {
  provides {
    interface Ieee154Address;
  }
  uses {
    interface LocalIeeeEui64;
    interface ActiveMessageAddress;
  }
} implementation {

  command ieee154_panid_t Ieee154Address.getPanId() {
    return call ActiveMessageAddress.amGroup();
  }
  command ieee154_saddr_t Ieee154Address.getShortAddr() {
    return call ActiveMessageAddress.amAddress();
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
    call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), addr);
    signal Ieee154Address.changed();
    return SUCCESS;
  }

  async event void ActiveMessageAddress.changed() {
    signal Ieee154Address.changed();
  }
}
