module FlashShellP {
  uses {
    interface Boot;
    interface Leds;
    interface ShellCommand;
    interface BlockRead;
    interface BlockWrite;
  }
} implementation {

  event void Boot.booted() {
    if (call BlockWrite.erase() != SUCCESS)
       call Leds.led1Toggle();
  }

  event void BlockRead.readDone(storage_addr_t addr, void* buf, storage_len_t len,
                                error_t error) {
    uint16_t r_len = snprintf(reply_buf, MAX_REPLY_LEN,"read done addr: 0x%x len: %i error: %i data: ", 
                              addr, len, error);
    if (len < MAX_REPLY_LEN - r_len - 1)
      memcpy(reply_buf + r_len, buf, len);
    reply_buf[r_len + len + 1] = '\n';
    call UDP.sendto(&session_endpoint, reply_buf, r_len + len + 1);
    
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len,
                                         uint16_t crc, error_t error) {

  }

  event void BlockWrite.writeDone(storage_addr_t addr, void* buf, storage_len_t len,
                                  error_t error) {
    uint16_t r_len = snprintf(reply_buf, MAX_REPLY_LEN,"write done addr: 0x%x len: %i error: %i\n", 
                              addr, len, error);
    call UDP.sendto(&session_endpoint, reply_buf, r_len);
  }

  event void BlockWrite.eraseDone(error_t error) {
    call Leds.led0Toggle();
  }

  event void BlockWrite.syncDone(error_t error) {

  }
}
