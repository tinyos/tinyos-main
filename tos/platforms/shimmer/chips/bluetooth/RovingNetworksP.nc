/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *  Author:  Steve Ayer
 *           February, 2007
 */
/**
 * @author Steve Ayer
 * @author Adrian Burns
 * @date February, 2007
 *
 * @author Mike Healy
 * @date April 20, 2009 - ported to TinyOS 2.x 
 */


#include "RovingNetworks.h"
#include "shimmerMessage.h"

module RovingNetworksP {
  provides {
    interface Init;
    interface StdControl;
    interface Bluetooth;
  }
  uses {
    interface HplMsp430Usart as UARTControl;
    interface HplMsp430UsartInterrupts as UARTData;
    interface HplMsp430Interrupt as RTSInterrupt;
    interface HplMsp430Interrupt as ConnectionInterrupt;

    interface Leds;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  uint8_t radioMode, charsSent, setupStep;
  bool discoverable, authenticate, encrypt, setNameRequest, setPINRequest, runDiscoveryRequest, resetDefaultsRequest,
    setSvcClassRequest, setDevClassRequest, setSvcNameRequest, setRawBaudrate, setBaudrate, disableRemoteConfig, newMode,
    setCustomInquiryTime, setCustomPagingTime;

  /* master mode stuff */
  int masterStep;
  bool deviceConn, btConnected, runningMasterCommands;
  char targetBt[16];

  norace bool transmissionOverflow, messageInProgress;
  char expectedCommandResponse[8], newName[17], newPIN[17], newSvcClass[5], newDevClass[5], newSvcName[17], newRawBaudrate[5],
    newBaudrate[5], newInquiryTime[5], newPagingTime[5];
  
  norace struct Message outgoingMsg;
  norace struct Message incomingMsg;

  task void sendNextChar() {
    if(charsSent < outgoingMsg.length) {
      call UARTControl.tx(msg_get_uint8(&outgoingMsg, charsSent));
      atomic charsSent++;
    } 
    else{
      messageInProgress = FALSE;
      atomic if(!*expectedCommandResponse)
	signal Bluetooth.writeDone();
    }	    
  }
  
  // note max message length is 128 bytes, beyond that msg_append_buf wraps
  command error_t Bluetooth.write(const uint8_t * buf, uint8_t len) { 
    if(messageInProgress)
      return FAIL;

    messageInProgress = TRUE;
    atomic charsSent = 0;
    msg_clear(&outgoingMsg);
    msg_append_buf(&outgoingMsg, buf, len);

    if(!transmissionOverflow){
      post sendNextChar();
    }
	
    return SUCCESS;
  }
    
  void initRN() {
    register uint16_t i;
    /*
     * powerup state is reset == low (true); mike conrad of roving networks sez: 
     * wait about 1/2 s after reset toggle
     */
    TOSH_SET_BT_RESET_PIN();    
    for(i = 0; i< 400; i++)
      TOSH_uwait(5000);

    TOSH_MAKE_BT_PIO_INPUT();   // this is the connection interrupt pin, was default output
    
    call RTSInterrupt.edge(TRUE);  // initially, we look for a connection
    call RTSInterrupt.enable();  // request to send raises when bt has trans overflow
    call RTSInterrupt.clear();
    
    call ConnectionInterrupt.edge(TRUE);  // initially, we look for a connection
    call ConnectionInterrupt.clear();
    call ConnectionInterrupt.enable();  // interrupt upon connection state change (raises when connected, falls when dropped)

    TOSH_CLR_BT_CTS_PIN();     // toggling cts wakes it up
    TOSH_SET_BT_CTS_PIN();     
    TOSH_uwait(5000);
    TOSH_CLR_BT_CTS_PIN();     // tell bt module msp430 is ready
  }

  void setupUART() {
    msp430_uart_union_config_t RN_uart_config = { {ubr: UBR_1MHZ_115200, umctl: UMCTL_1MHZ_115200, 
						   ssel: 0x02, pena: 0, pev: 0, spb: 0, clen: 1,listen: 0, mm: 0, ckpl: 0, urxse: 0, urxeie: 0, 
						   urxwie: 0, utxe : 1, urxe :1} };

    call UARTControl.setModeUart(&RN_uart_config); // set to UART mode

#ifdef USE_8MHZ_CRYSTAL           // we need exact divisors, else the thing acts unpredictably
    call UARTControl.setUbr(0x08);
    call UARTControl.setUmctl(0xee);

    /* 4000000hz smclk
    call UARTControl.setUbr(0x22);
    call UARTControl.setUmctl(0xdd);
    */
#endif

    /*
     * to run the bt module at 230k, first the application must configure it
     * using its default uart speed of 115200, then reset the uart to 230k here
     * see accompanying bluetoothBaudrateConfiguration.pdf doc for details
     * yes, doc is written for tos-1.x, but setClockRate() is just broken into
     * two calls here in tos-2.x
     *
     call UARTControl.setUbr(0x04);
     call UARTControl.setUmctl(0x82);
    */
    
    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  void disableRN() {
    TOSH_CLR_BT_RESET_PIN();
    call UARTControl.disableUart();
    call RTSInterrupt.disable();  
    call ConnectionInterrupt.disable();  
  }

  error_t writeCommand(char * cmd, char * response) {
    atomic strcpy(expectedCommandResponse, response);
    if(call Bluetooth.write(cmd, strlen(cmd)) == FAIL)
      return FAIL;

    return SUCCESS;
  }

  /* 
   * Connect and Disconnect commands are exceptional commands in that 
   * they automatically return to data mode once they are issued 
   */
  error_t writeCommandNoRsp(char * cmd) {
    if(call Bluetooth.write(cmd, strlen(cmd)) == FAIL)
      return FAIL;

    return SUCCESS;
  }

  command void Bluetooth.setRadioMode(uint8_t mode){
    newMode = TRUE;
    radioMode = mode;
  }    

  command void Bluetooth.setDiscoverable(bool disc){
    discoverable = disc;  
  }    

  command void Bluetooth.setEncryption(bool enc){
    encrypt = enc; 
  }    

  command void Bluetooth.setAuthentication(bool auth){
    authenticate = auth;
  }    

  command void Bluetooth.disableRemoteConfig(bool disableConfig){
    disableRemoteConfig = disableConfig;
  }    

  command void Bluetooth.resetDefaults(){
    resetDefaultsRequest = TRUE;
  }    

  command void Bluetooth.setName(char * name){
    setNameRequest = TRUE;
    snprintf(newName, 17, "%s", name);
  }    

  command void Bluetooth.setDeviceClass(char * class){
    setDevClassRequest = TRUE;
    snprintf(newDevClass, 5, "%s", class);
  }    

  command void Bluetooth.setServiceClass(char * class){
    setSvcClassRequest = TRUE;
    snprintf(newSvcClass, 5, "%s", class);
  }    

  command void Bluetooth.setServiceName(char * name){
    setSvcNameRequest = TRUE;
    snprintf(newSvcName, 5, "%s", name);
  }    

  /* 
   * this one makes sense only to roving networks
   * the supplied "rate_factor" is the baudrate * 0.004096
   * this factor must be an integer value...
   */
  command void Bluetooth.setRawBaudrate(char * rate_factor){
    setRawBaudrate = TRUE;
    snprintf(newRawBaudrate, 5, "%s", rate_factor);
  }    

  /* 
   * to set the baudrate of the BT to MSP serial interface 
   * as per RovingNetworks command spec EG "SU,96" or "SU,230"
   * SU,<rate> - Baudrate, {1200, 2400, 4800, 9600, 19.2, 
   * 38.4, 57.6, 115K, 230K, 460K, 921K },
   * BUT, the MSP USARTS will not run at > 230K in UART mode, 
   * see MSP user guide
   */
  command void Bluetooth.setBaudrate(char * new_baud){
    setBaudrate = TRUE;
    snprintf(newBaudrate, 5, "%s", new_baud);
  }    

  command void Bluetooth.setPIN(char * PIN){
    setPINRequest = TRUE;
    snprintf(newPIN, 17, "%s", PIN);
  }    

  /* 
   * Sets the Inquiry Scan Window - amount of time device 
   * spends enabling inquiry scan (discoverability).
   * Minimum = (hex word) "0012", corresponding to about 1% duty cycle.
   * Maximum = (hex word) "1000"
   */
  command void Bluetooth.setInquiryTime(char * hexval_time){
    setCustomInquiryTime = TRUE;
    snprintf(newInquiryTime, 5, "%s", hexval_time);
  }    

  /* 
   * Sets the Paging Scan Window - amount of time device 
   * spends enabling page scan (connectability).
   * Minimum = (hex word) "0012", corresponding to about 1% duty cycle.
   * Maximum = (hex word) "1000"
   */
  command void Bluetooth.setPagingTime(char * hexval_time){
    setCustomPagingTime = TRUE;
    snprintf(newPagingTime, 5, "%s", hexval_time);
  }    

  /* 
   * IMPORTANT: Connect and Disconnect commands are exceptional commands 
   * in that they automatically return to data mode once they are issued
   * so no response and no "---" needed to return to data mode 
   */
  task void runMasterCommands()
  {
    char commandbuf[32];
    switch(masterStep){
    case 0:
      masterStep++;
      writeCommand("$$$", "CMD");
      break;
    case 1:
      masterStep++;
      // Connect
      if(deviceConn && (!btConnected)){
	masterStep = -1;
	sprintf(commandbuf, "C,%s\r", targetBt);
	writeCommandNoRsp(commandbuf);
	runningMasterCommands = FALSE;
	break;
      }
    case 2:
      masterStep++;
      // Disconnect
      if((!deviceConn) && (btConnected)) {
	masterStep = -1;
	writeCommandNoRsp("K,\r");
	runningMasterCommands = FALSE;          
	break;
      }
    case 3:
      /* not needed for connect and disconnect commands */
      masterStep++;
      // exit command mode
      writeCommand("---\r", "END");
      break;
    default:
      deviceConn = FALSE;
      runningMasterCommands = FALSE;
      break;
    }
  }

  command error_t Bluetooth.connect(uint8_t *addr)
  {
    masterStep = 0;
    deviceConn = runningMasterCommands = TRUE;
    strcpy(targetBt, addr);
    post runMasterCommands();
    return SUCCESS;
  }

  command error_t Bluetooth.disconnect()
  {
    register uint16_t i;
    /*
     * Delay: If any bytes are seen before or after $$$ in a 1 
     * second window, command mode will not be entered and these 
     * bytes will be passed on to other side 
     */
    for(i = 0; i < 1600 ; i++)
      TOSH_uwait(5000);

    masterStep = 0;
    deviceConn = FALSE;
    runningMasterCommands = TRUE;
    post runMasterCommands();
    
    return SUCCESS;
  }

  /*
   * this one is weird.  we need to do one at a time; the only way
   * to get back is if the previous command responds properly and calls
   * back to runSetCommands().  so if we get into command mode, each time here 
   * we have to send another command.  we keep falling down the switch 
   * until we find it, eventually hitting end.
   */
  task void runSetCommands() {
    char commandbuf[32];

    switch(setupStep) {
    case 0:
      setupStep++;
      writeCommand("$$$", "CMD");
      break;
    case 1:
      setupStep++;
      // reset factory defaults
      if(resetDefaultsRequest){
	writeCommand("SF,1\r", "AOK");
	break;
      }
    case 2:
      setupStep++;
      // default is slave (== 0), otherwise set mode
      if(newMode){
	sprintf(commandbuf, "SM,%d\r", radioMode);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 3:
      setupStep++;
      /*
       * device is discoverable with a non-zero inquiry scan window
       * default "time" is 0x0200 (units unspecified)
       */
      if(!discoverable){
	writeCommand("SI,0000\r", "AOK");
	break;
      }
    case 4:
      setupStep++;
      // device default is off
      if(authenticate){
	writeCommand("SA,1\r", "AOK");
	break;
      }
    case 5:
      setupStep++;
      // device default is off
      if(encrypt){
	writeCommand("SE,1\r", "AOK");
	break;
      }
    case 6:
      setupStep++;
      // default is none
      if(setNameRequest){
	sprintf(commandbuf, "SN,%s\r", newName);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 7:
      setupStep++;
      // default is none
      if(setPINRequest){
	sprintf(commandbuf, "SP,%s\r", newPIN);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 8:
      setupStep++;
      if(setSvcClassRequest){
	sprintf(commandbuf, "SC,%s\r", newSvcClass);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 9:
      setupStep++;
      if(setDevClassRequest){
	sprintf(commandbuf, "SD,%s\r", newDevClass);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 10:
      setupStep++;
      if(setSvcNameRequest){
	sprintf(commandbuf, "SS,%s\r", newSvcName);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 11:
      setupStep++;
      if(setRawBaudrate){
	// set the baudrate to suit the MSP430 running at 8Mhz
	sprintf(commandbuf, "SZ,%s\r", newRawBaudrate);
	writeCommand(commandbuf, "AOK");
	break;
      }
    case 12:
      setupStep++;
      if(disableRemoteConfig){
	// disable remote configuration to enhance throughput
	writeCommand("ST,0\r", "AOK");
      }
      else{
	// disable remote configuration to enhance throughput
	writeCommand("ST,60\r", "AOK");
      }
      break;
    case 13:
      setupStep++;
      if(setCustomInquiryTime){
	sprintf(commandbuf, "SI,%s\r", newInquiryTime);
	writeCommand(commandbuf, "AOK");
      }
      else{
	// to save power only leave inquiry on for approx 40msec (every 1.28 secs)
	writeCommand("SI,0040\r", "AOK");
      }
      break;
    case 14:
      setupStep++;
      if(setCustomPagingTime){
	sprintf(commandbuf, "SJ,%s\r", newPagingTime);
	writeCommand(commandbuf, "AOK");
      }
      else{
	// to save power only leave paging on for approx 80msec (every 1.28 secs)
	writeCommand("SJ,0080\r", "AOK");
      }
      break;
    case 15:
      setupStep++;
      if(setBaudrate){
        // set the baudrate to suit the MSP430 running at 8Mhz
        sprintf(commandbuf, "SU,%s\r", newBaudrate);
        writeCommand(commandbuf, "AOK");
        break;
      }

    case 16:
      setupStep++;
      // exit command mode
      writeCommand("---\r", "END");
      break;
    default:
      break;
    }
  }  

  command error_t Init.init(){
    TOSH_MAKE_BT_RTS_INPUT();      
    
    TOSH_MAKE_BT_RXD_INPUT();
    TOSH_SEL_BT_RXD_MODFUNC();
    
    // this powers it up on models so equipped, otherwise harmless 
#ifdef BT_PWR_LOGIC_TRUE
    TOSH_SET_SW_BT_PWR_N_PIN();
#else	
    TOSH_CLR_SW_BT_PWR_N_PIN();   
#endif
    
    newMode = FALSE;
    radioMode = SLAVE_MODE;   
    discoverable = TRUE;
    authenticate = FALSE;
    encrypt = FALSE;
    resetDefaultsRequest = FALSE;
    setNameRequest = FALSE;
    setPINRequest = FALSE;
    setSvcClassRequest = FALSE;
    setSvcNameRequest = FALSE;
    setDevClassRequest = FALSE;
    setRawBaudrate = FALSE;
    disableRemoteConfig = FALSE;
    setCustomInquiryTime = FALSE;
    setCustomPagingTime = FALSE;
    setBaudrate = FALSE;

    /* connect/disconnect commands */
    deviceConn = btConnected = runningMasterCommands = FALSE;
    masterStep = setupStep = 0;

    atomic *expectedCommandResponse = 0;   // NULL pointer
    transmissionOverflow = FALSE, messageInProgress = FALSE;

    initRN();
    
    setupUART();

    return SUCCESS;
  }

  command error_t StdControl.start(){
    TOSH_uwait(15000);
    post runSetCommands();

    return SUCCESS;
  }

  command error_t StdControl.stop(){
    disableRN();
    
#ifdef BT_PWR_LOGIC_TRUE
    TOSH_CLR_SW_BT_PWR_N_PIN();
#else	
    TOSH_SET_SW_BT_PWR_N_PIN();   
#endif
    
    return SUCCESS;
  }

  /* commands useful for Master(client) applications only */
  /* do an BT Inquiry to discover all listening devices within range */
  command void Bluetooth.discoverDevices() {
    if(!radioMode)     // we're a slave, shouldn't do this
      return;

    runDiscoveryRequest = TRUE;
  }    

  async event void UARTData.rxDone(uint8_t data) {        
    if(!*expectedCommandResponse){
      signal Bluetooth.dataAvailable(data);
    }
    else{
      if(isalpha(data)){
	msg_append_uint8(&incomingMsg, data);
	if(msg_cmp_buf(&incomingMsg,            // which is affirmative
		       0, 
		       expectedCommandResponse,
		       strlen(expectedCommandResponse))){
	  msg_clear(&incomingMsg);	
	  if(!strcmp(expectedCommandResponse, "END"))
	    signal Bluetooth.commandModeEnded();  //call Leds.greenOn();
	  else if(runningMasterCommands)  
	    post runMasterCommands();
	  else
	    post runSetCommands();
	  atomic *expectedCommandResponse = '\0';
	}
      }
      else
	msg_clear(&incomingMsg);
    }
  }

  async event void UARTData.txDone() {
    if (!transmissionOverflow) {
      post sendNextChar();
    }
  }
    
  // Interrupt associated with radio flow control.  Ensures that there are no buffer overflows.
  async event void RTSInterrupt.fired() {
    if (call RTSInterrupt.getValue() == TRUE) {
      transmissionOverflow = 1;
      call RTSInterrupt.edge(FALSE);
    } 
    else{
      atomic transmissionOverflow = 0;
      post sendNextChar();
      call RTSInterrupt.edge(TRUE);
    }
    atomic call RTSInterrupt.clear();
  }
  
  async event void ConnectionInterrupt.fired() {
    if(call ConnectionInterrupt.getValue() == TRUE){
      btConnected = TRUE;
      call ConnectionInterrupt.edge(FALSE);
      signal Bluetooth.connectionMade(SUCCESS);
    }
    else{
      btConnected = FALSE;
      call ConnectionInterrupt.edge(TRUE);
      signal Bluetooth.connectionClosed(0);
    }
    atomic call ConnectionInterrupt.clear();
  }
}
