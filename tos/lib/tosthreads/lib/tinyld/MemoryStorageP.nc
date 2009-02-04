module MemoryStorageP
{
  provides interface BlockRead;
  uses interface Crc;
}

implementation
{
  storage_addr_t retAddr;
  void *retBuf;
  storage_len_t retLen;
  uint16_t retCrc;

  task void taskReadDone()
  {
    signal BlockRead.readDone(retAddr, retBuf, retLen, SUCCESS);
  }

  command error_t BlockRead.read(storage_addr_t addr, void* buf, storage_len_t len)
  {
    storage_len_t i;
    uint8_t *from = (uint8_t *)((void *)((uint16_t)addr));
    
    for (i = 0; i < len; i++) {
      ((uint8_t *)buf)[i] = from[i];
    }
    
    retAddr = addr;
    retBuf = buf;
    retLen = len;
    post taskReadDone();
    return SUCCESS;
  }
  
  task void taskCrcDone()
  {
    signal BlockRead.computeCrcDone(retAddr, retLen, retCrc, SUCCESS);
  }
  
  command error_t BlockRead.computeCrc(storage_addr_t addr, storage_len_t len, uint16_t crc)
  {
    retCrc = call Crc.seededCrc16(crc, (void *)addr, len);
    retAddr = addr;
    retLen = len;
    post taskCrcDone();
    return SUCCESS;
  }
  
  command storage_len_t BlockRead.getSize()
  {
    return 0;   // Not sure what to do
  }
  
  default event void BlockRead.readDone(storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
}
