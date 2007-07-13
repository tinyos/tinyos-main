interface XE1205PhyRssi {

    async command error_t getRssi();
    command uint8_t readRxRssi();
    async event void rssiDone(uint8_t _rssi);
}
