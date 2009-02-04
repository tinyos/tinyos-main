module BigCrcP {
  provides interface BigCrc;
  uses interface Crc;
}

implementation {
  bool isBusy = FALSE;
  void* inbuf;
  uint16_t inlen;
  uint16_t pos;
  uint16_t computedCrc;

  task void computeCrc()
  {
    uint8_t len = 0xFF;
    if (inlen < 0xFF) {
      len = inlen;
    }
    computedCrc = call Crc.seededCrc16(computedCrc, inbuf + pos, len);
    inlen -= len;
    pos += len;
    
    if (inlen > 0) {
      post computeCrc();
    } else {
      isBusy = FALSE;
      signal BigCrc.computeCrcDone(inbuf, pos + 1, computedCrc, SUCCESS);
    }
  }

  command error_t BigCrc.computeCrc(void* buf, uint16_t len)
  {
    if (isBusy == TRUE) {
      return EBUSY;
    }
    
    inbuf = buf;
    inlen = len;
    computedCrc = pos = 0;
    post computeCrc();
    
    return SUCCESS;
  }
}
