module eyesIFXSerialP {
 provides interface StdControl;
 provides interface Msp430UartConfigure;
 uses interface Resource;
}
implementation {
  //msp430_uart_config_t msp430_uart_eyes_config = {ubr: UBR_1MHZ_115200, umctl: UMCTL_1MHZ_115200, ssel: 0x02, pena: 0, pev: 0, spb: 0, clen: 1, listen: 0, mm: 0, ckpl: 0, urxse: 0, urxeie: 1, urxwie: 0};
  
  // when the tda5250 is in receive mode we get problems with 115200 baud 
  // on the serial line ...
  msp430_uart_config_t msp430_uart_eyes_config = {ubr: UBR_1MHZ_57600, umctl: UMCTL_1MHZ_57600, ssel: 0x02, pena: 0, pev: 0, spb: 0, clen: 1, listen: 0, mm: 0, ckpl: 0, urxse: 0, urxeie: 1, urxwie: 0};

  command error_t StdControl.start(){
    return call Resource.immediateRequest();
  }
  command error_t StdControl.stop(){
    call Resource.release();
    return SUCCESS;
  }
  event void Resource.granted(){}

  async command msp430_uart_config_t* Msp430UartConfigure.getConfig() {
    return &msp430_uart_eyes_config;
  }
}
