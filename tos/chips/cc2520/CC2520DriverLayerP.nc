/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (port to CC2520)
 * Author: JeongGil Ko (CC2520 modifications and security support)
 */

#include <CC2520DriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>

module CC2520DriverLayerP
{
  provides{
    interface Init as SoftwareInit @exactlyonce();

    interface RadioState;
    interface RadioSend;
    interface RadioReceive;
    interface RadioCCA;
    interface RadioPacket;

    interface PacketField<uint8_t> as PacketTransmitPower;
    interface PacketField<uint8_t> as PacketRSSI;
    interface PacketField<uint8_t> as PacketTimeSyncOffset;
    interface PacketField<uint8_t> as PacketLinkQuality;
    //interface PacketField<uint8_t> as AckReceived;
    interface PacketAcknowledgements;
  }

  uses{
    interface BusyWait<TMicro, uint16_t>;
    interface LocalTime<TRadio>;
    interface CC2520DriverConfig as Config;

    interface Resource as SpiResource;
    interface SpiByte;
    interface SpiPacket;
    interface GeneralIO as CSN;
    interface GeneralIO as VREN;
    interface GeneralIO as CCA;
    interface GeneralIO as RSTN;
    interface GeneralIO as FIFO;
    interface GeneralIO as FIFOP;
    interface GeneralIO as SFD;
    interface GpioCapture as SfdCapture;
    interface GpioInterrupt as FifopInterrupt;
    interface GpioInterrupt as FifoInterrupt;

    interface PacketFlag as TransmitPowerFlag;
    interface PacketFlag as RSSIFlag;
    interface PacketFlag as TimeSyncFlag;
    interface PacketFlag as AckReceivedFlag;

    interface PacketTimeStamp<TRadio, uint32_t>;

    interface Tasklet;
    interface RadioAlarm;

#ifdef RADIO_DEBUG_MESSAGES
    interface DiagMsg;
#endif
    interface Leds;
    interface Draw;

    interface CC2520Security;
  }
}

implementation{

#define HI_UINT16(val) (((val) >> 8) & 0xFF)
#define LO_UINT16(val) ((val) & 0xFF)
#define ADDR_DATA 0x200
#define ADDR_NONCE 0x320
#define ADDR_KEY 0x340
#define HIGH_PRIORITY 1
#define LOW_PRIORITY 0
#define NONCE_FLAG_BYTE 0x09

  inline void serviceRadio();
  inline void downloadMessage();

  uint8_t pKey[]= {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  };

  uint8_t decNonce[]= {
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
  };

  uint8_t encNonce[]= {
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
  };

  cc2520_header_t* getHeader(message_t* msg)
  {
    return ((void*)msg) + call Config.headerLength(msg);
  }

  /*
   * Return a pointer to the data portion of the message.
   */
  void* getPayload(message_t* msg){
    return ((void*)msg)  + call RadioPacket.headerLength(msg);
  }

  cc2520_metadata_t* getMeta(message_t* msg){
    return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
  }

  /*----------------- STATE -----------------*/

  enum{
    STATE_VR_ON = 0,
    STATE_PD = 1,
    STATE_PD_2_IDLE = 2,
    STATE_IDLE = 3,
    STATE_IDLE_2_RX_ON = 4,
    STATE_RX_ON = 5,
    STATE_BUSY_TX_2_RX_ON = 6,
    STATE_IDLE_2_TX_ON = 7,
    STATE_TX_ON = 8,
    STATE_RX_DOWNLOAD = 9,
  };

  tasklet_norace uint8_t state = STATE_VR_ON;

  enum{
    CMD_NONE = 0,           // the state machine has stopped
    CMD_TURNOFF = 1,        // goto SLEEP state
    CMD_STANDBY = 2,        // goto TRX_OFF state
    CMD_TURNON = 3,         // goto RX_ON state
    CMD_TRANSMIT = 4,       // currently transmitting a message
    CMD_RECEIVE = 5,        // currently receiving a message
    CMD_CCA = 6,            // performing clear chanel assesment
    CMD_CHANNEL = 7,        // changing the channel
    CMD_SIGNAL_DONE = 8,        // signal the end of the state transition
    CMD_DOWNLOAD = 9,       // download the received message
  };

  tasklet_norace uint8_t cmd = CMD_NONE;

  norace bool radioIrq = 0;

  tasklet_norace uint8_t txPower;
  tasklet_norace uint8_t channel;

  tasklet_norace message_t* rxMsg;
  //#ifdef RADIO_DEBUG_MESSAGES
  tasklet_norace message_t* txMsg;
  //#endif
  message_t rxMsgBuffer;

  uint32_t capturedTime;  // the current time when the last interrupt has occured

  tasklet_norace uint8_t rssiClear;
  tasklet_norace uint8_t rssiBusy;
  norace bool first_packet = TRUE;
  norace bool sending = FALSE;
  norace bool receiving = FALSE;
  norace bool security_processing = FALSE;

  // used to continue tx after sfd
  norace uint8_t* txData;
  norace uint8_t header;
  norace uint8_t prevdata9, prevdata10;
  norace uint8_t secMode;
  norace uint8_t txLength;
  norace ieee154_simple_header_t* txIeee154header;

  enum{ // FIXME: need to check these for CC2520
    TX_SFD_DELAY = (uint16_t)(0 * RADIO_ALARM_MICROSEC),
    RX_SFD_DELAY = (uint16_t)(7 * RADIO_ALARM_MICROSEC/2),
  };

  inline cc2520_status_t getStatus();
  //inline void sendDoneSignal(error_t error, bool ack);

  tasklet_async event void RadioAlarm.fired(){

    if( state == STATE_PD_2_IDLE ) {
      state = STATE_IDLE;
      if( cmd == CMD_STANDBY )
        cmd = CMD_SIGNAL_DONE;
    }
    else if( state == STATE_IDLE_2_RX_ON ) {
      state = STATE_RX_ON;
      // in receive mode, enable SFD capture
      //call SfdCapture.captureRisingEdge(); //JK

      cmd = CMD_SIGNAL_DONE;
    }else{
      RADIO_ASSERT(FALSE);
    }

    // make sure the rest of the command processing is called
    call Tasklet.schedule();
  }

  /*----------------- REGISTER -----------------*/

  inline cc2520_status_t writeRegister(uint8_t reg, uint8_t value){
    cc2520_status_t status;
    uint8_t v;

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    if( reg <= CC2520_FREG_MASK){
      // we can use 1 byte less to write this register using the
      // register write command

      RADIO_ASSERT( reg == (reg & CC2520_FREG_MASK) );


      status.value = call SpiByte.write(CC2520_CMD_REGISTER_WRITE | reg);

    }
    else{
      // we have to use the memory write command as the register is in
      // SREG

      RADIO_ASSERT( reg == (reg & CC2520_SREG_MASK) );

      // the register has to be below the 0x100 memory address. Thus, we
      // don't have to add anything to the MEMORY_WRITE command.
      status.value = call SpiByte.write(CC2520_CMD_MEMORY_WRITE);
      status.value = call SpiByte.write(reg);

    }
    // v is the value previously in the register
    v = call SpiByte.write(value);

    call CSN.set();

    return status;

  }

  /* New function by JK  -- identical to MEMWR function */
  /* This function is to write data to memory spaces above 0x200 */
  inline cc2520_status_t writeMemory(uint16_t mem_addr, uint8_t* value, uint8_t count){
    cc2520_status_t status;
    uint8_t v, i;

    if(mem_addr < 0x200){
      mem_addr = 0x200;
    }

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    status.value = call SpiByte.write(CC2520_CMD_MEMORY_WRITE | HI_UINT16(mem_addr));
    status.value = call SpiByte.write(LO_UINT16(mem_addr));

    for(i=0;i<count;i++){
      v = call SpiByte.write(value[i]);
    }

    /*
       s = CC2520_SPI_TXRX(CC2520_INS_MEMWR | HI_UINT16(addr));
       CC2520_SPI_TXRX(LO_UINT16(addr));
       while (count--) {
       CC2520_SPI_TX(*pData);
       pData++;
       CC2520_SPI_WAIT_RXRDY();
       }
       */

    call CSN.set();

    return status;
  }

  // JK: Need to check!
  inline uint8_t readMemory(uint16_t mem_addr, uint8_t* buf, uint8_t count){
    uint8_t i, value = 0;

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_MEMORY_READ | HI_UINT16(mem_addr));
    call SpiByte.write(LO_UINT16(mem_addr));

    for(i=0;i<count;i++){
      buf[i] = call SpiByte.write(0);
    }

    /*
       s = CC2520_SPI_TXRX(CC2520_INS_MEMRD | HI_UINT16(addr));
       CC2520_SPI_TXRX(LO_UINT16(addr));
       CC2520_INS_RD_ARRAY(count, pData);
       */

    call CSN.set();

    return value;
  }


  inline void CCM(uint8_t priority, uint8_t key_addr, uint8_t payload_len, uint8_t nonce_addr, uint16_t start_addr, uint16_t dest_addr, uint8_t auth_len, uint8_t mic_len){

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_CCM | priority);
    call SpiByte.write(key_addr);
    call SpiByte.write(payload_len);
    call SpiByte.write(nonce_addr);
    call SpiByte.write((HI_UINT16(start_addr) << 4) | HI_UINT16(dest_addr));
    call SpiByte.write(LO_UINT16(start_addr));
    call SpiByte.write(LO_UINT16(dest_addr));
    call SpiByte.write(auth_len);
    call SpiByte.write(mic_len);

    call CSN.set();

    return;

  }

  inline void UCCM(uint8_t priority, uint8_t key_addr, uint8_t payload_len, uint8_t nonce_addr, uint16_t start_addr, uint16_t dest_addr, uint8_t auth_len, uint8_t mic_len){

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_CCM | priority);
    call SpiByte.write(key_addr);
    call SpiByte.write(payload_len);
    call SpiByte.write(nonce_addr);
    call SpiByte.write((HI_UINT16(start_addr) << 4) | HI_UINT16(dest_addr));
    call SpiByte.write(LO_UINT16(start_addr));
    call SpiByte.write(LO_UINT16(dest_addr));
    call SpiByte.write(auth_len);
    call SpiByte.write(mic_len);

    call CSN.set();

    return;
  }

  inline void CBCMAC(uint8_t priority, uint8_t key_addr, uint8_t payload_len, uint16_t start_addr, uint16_t dest_addr, uint8_t mic_len){

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_CCM | priority);
    call SpiByte.write(key_addr);
    call SpiByte.write(payload_len);
    call SpiByte.write((HI_UINT16(start_addr) << 4) | HI_UINT16(dest_addr));
    call SpiByte.write(LO_UINT16(start_addr));
    call SpiByte.write(LO_UINT16(dest_addr));
    call SpiByte.write(mic_len);

    call CSN.set();

    return;

  }

  inline void UCBCMAC(){}

  inline void CTR(uint8_t priority, uint8_t key_addr, uint8_t payload_len, uint8_t nonce_addr, uint16_t start_addr, uint16_t dest_addr){
    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_CTR_UCTR | priority);
    call SpiByte.write(key_addr);
    call SpiByte.write(payload_len);
    call SpiByte.write(nonce_addr);

    call SpiByte.write((HI_UINT16(start_addr) << 4) | HI_UINT16(dest_addr));
    call SpiByte.write(LO_UINT16(start_addr));
    call SpiByte.write(LO_UINT16(dest_addr));

    call CSN.set();

    return;
  }

  inline void UCTR(uint8_t priority, uint8_t key_addr, uint8_t payload_len, uint8_t nonce_addr, uint16_t start_addr, uint16_t dest_addr){
    CTR(priority, key_addr, payload_len, nonce_addr, start_addr, dest_addr);
    return;
  }


  inline void MEMCP(uint8_t priority, uint16_t count, uint16_t start_addr, uint16_t dest_addr){

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    call SpiByte.write(CC2520_CMD_MEMCP | priority);
    call SpiByte.write(count);
    call SpiByte.write((HI_UINT16(start_addr) << 4) | HI_UINT16(dest_addr));
    call SpiByte.write(LO_UINT16(start_addr));
    call SpiByte.write(LO_UINT16(dest_addr));

    call CSN.set();

    return;

  }

  /*
   * Strobes changed a lot between CC2420 and CC2520. They are now just an
   * other command, without any parameters.
   */
  inline cc2520_status_t strobe(uint8_t reg){
    cc2520_status_t status;

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    status.value = call SpiByte.write(reg);

    call CSN.set();
    return status;

  }

  inline cc2520_status_t getStatus() {
    return strobe(CC2520_CMD_SNOP);
  }

  inline uint8_t readRegister(uint8_t reg){
    uint8_t value = 0;

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    if( reg <= CC2520_FREG_MASK ){
      RADIO_ASSERT( reg == (reg & CC2520_FREG_MASK) );
      call SpiByte.write(CC2520_CMD_REGISTER_READ | reg);

    }
    else{
      RADIO_ASSERT( reg == (reg & CC2520_SREG_MASK) );

      call SpiByte.write(CC2520_CMD_MEMORY_WRITE);
      call SpiByte.write(reg);
    }

    value = call SpiByte.write(0);
    call CSN.set();

    return value;
  }

  inline cc2520_status_t writeTxFifo(uint8_t* data, uint8_t length){
    cc2520_status_t status;
    uint8_t idx;

    RADIO_ASSERT( call SpiResource.isOwner() );

    call CSN.set();
    call CSN.clr();

    status.value = call SpiByte.write(CC2520_CMD_TXBUF);
    // FIXME: replace this at some point with a SPIPacket call.
    for(idx = 0; idx<length; idx++)
      call SpiByte.write(data[idx]);

    call CSN.set();

    return status;

  }

  inline uint8_t waitForRxFifoNoTimeout() {
    // wait for fifo to go high
    while(call FIFO.get() == 0);

    return call FIFO.get();
  }

  inline uint8_t waitForRxFifo() {
    // wait for fifo to go high or timeout
    // timeout is now + 2 byte time (4 symbol time)
    uint16_t timeout = call RadioAlarm.getNow() + 4 * CC2520_SYMBOL_TIME;

    while(call FIFO.get() == 0 && (timeout - call RadioAlarm.getNow() < 0x7FFF));
    return call FIFO.get();
  }

  inline cc2520_status_t readLengthFromRxFifo(uint8_t* lengthPtr){
    cc2520_status_t status;

    RADIO_ASSERT( call SpiResource.isOwner() );
    RADIO_ASSERT( call CSN.get() == 1 );

    // FIXME: ???? why do we do this ????
    call CSN.set();
    call CSN.clr();
    call CSN.set();
    call CSN.clr();
    call CSN.set();
    call CSN.clr();

    status.value = call SpiByte.write(CC2520_CMD_RXBUF);
    //waitForRxFifoNoTimeout();
    *lengthPtr = call SpiByte.write(0);
    return status;
  }

  inline cc2520_status_t readLengthFromRxFifo_cp(uint8_t* lengthPtr){
    cc2520_status_t status;

    RADIO_ASSERT( call SpiResource.isOwner() );
    RADIO_ASSERT( call CSN.get() == 1 );

    // FIXME: ???? why do we do this ????
    call CSN.set();
    call CSN.clr();
    call CSN.set();
    call CSN.clr();
    call CSN.set();
    call CSN.clr();

    status.value = call SpiByte.write(CC2520_CMD_RXBUFCP);
    //waitForRxFifoNoTimeout();
    *lengthPtr = call SpiByte.write(0);
    return status;
  }


  inline void readPayloadFromRxFifo(uint8_t* data, uint8_t length){
    uint8_t idx;

    // readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
    RADIO_ASSERT( call CSN.get() == 0 );

    for(idx = 0; idx<length; idx++) {
      //waitForRxFifo();
      RADIO_ASSERT(call FIFO.get());
      data[idx] = call SpiByte.write(0);
    }
  }

  inline void readRssiFromRxFifo(uint8_t* rssiPtr){
    // FIXME: make sure that RSSI is added to the frame in the
    // configuration! See 20.3.4 in CC2520 Manual (Dec. 2007)

    // readLengthFromRxFifo was called before, so CSN is cleared and spi is ours

    //waitForRxFifo();
    RADIO_ASSERT(call FIFO.get());
    *rssiPtr = call SpiByte.write(0);
  }

  inline void readCrcOkAndLqiFromRxFifo(uint8_t* crcOkAndLqiPtr){
    // readLengthFromRxFifo was called before, so CSN is cleared and spi is ours

    RADIO_ASSERT( call CSN.get() == 0 );

    //waitForRxFifo(); // JK
    *crcOkAndLqiPtr = call SpiByte.write(0);

    // end RxFifo read operation
    call CSN.set();
  }

  inline void flushRxFifo() {
    // set it to stop possible pending fifo transfer

    {
      cc2520_status_t status;


      strobe(CC2520_CMD_SFLUSHRX);
      strobe(CC2520_CMD_SFLUSHRX);
      strobe(CC2520_CMD_SFLUSHRX);
      status = strobe(CC2520_CMD_SFLUSHRX);

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        call DiagMsg.str("b_flush");
        call DiagMsg.uint8(status.value);
        call DiagMsg.send();
      }
#endif
    }
  }

  /*----------------- INIT -----------------*/

  command error_t SoftwareInit.init(){
    // set pin directions
    call CSN.makeOutput();
    call VREN.makeOutput();
    call RSTN.makeOutput();
    call CCA.makeInput();
    call SFD.makeInput();
    call FIFO.makeInput();
    call FIFOP.makeInput();

    call FifopInterrupt.disable();
    call FifopInterrupt.enableRisingEdge();

    call FifoInterrupt.disable();
    call FifoInterrupt.enableRisingEdge();

    call SfdCapture.disable();
    // rising edge just saves timestamp.
    call SfdCapture.captureRisingEdge();

    // CSN is active low
    call CSN.set();

    // start up voltage regulator
    call VREN.clr();
    call VREN.set();
    // do a reset
    call RSTN.clr();
    // hold line low for Tdres
    call BusyWait.wait( 200 ); // typical .1ms VR startup time

    call RSTN.set();
    // wait another .2ms for xosc to stabilize
    call BusyWait.wait( 200 );

    rxMsg = &rxMsgBuffer;

    state = STATE_VR_ON;

    // request SPI, rest of the initialization will be done from
    // the granted event
    return call SpiResource.request();
  }

  inline void resetRadio() {
    // now register access is enabled: set up defaults
    cc2520_fifopctrl_t fifopctrl;
    cc2520_frmfilt0_t frmfilt0;
    cc2520_frmfilt1_t frmfilt1;
    cc2520_srcmatch_t srcmatch;
    //cc2520_frmctrl0_t frmctrl0;

    // do a reset
    call RSTN.clr();
    //call BusyWait.wait( 200 ); //
    call RSTN.set();

    // update default values of registers
    // given from SWRS068, December 2007, Section 28.1
    writeRegister(CC2520_TXPOWER, cc2520_txpower_default.value);
    writeRegister(CC2520_CCACTRL0, cc2520_ccactrl0_default.value);
    writeRegister(CC2520_MDMCTRL0, cc2520_mdmctrl0_default.value);
    writeRegister(CC2520_MDMCTRL1, cc2520_mdmctrl1_default.value);
    writeRegister(CC2520_RXCTRL, cc2520_rxctrl_default.value);
    writeRegister(CC2520_FSCTRL, cc2520_fsctrl_default.value);
    writeRegister(CC2520_FSCAL1, cc2520_fscal1_default.value);
    writeRegister(CC2520_AGCCTRL1, cc2520_agcctrl1_default.value);
    writeRegister(CC2520_ADCTEST0, cc2520_adctest0_default.value);
    writeRegister(CC2520_ADCTEST1, cc2520_adctest1_default.value);
    writeRegister(CC2520_ADCTEST2, cc2520_adctest2_default.value);

    // setup fifop threshold
    fifopctrl.f.fifop_thr = 127;
    writeRegister(CC2520_FIFOPCTRL, fifopctrl.value);

    // FIXME: disable frame filtering for now
    frmfilt0 = cc2520_frmfilt0_default;
    frmfilt0.f.frame_filter_en = 0;
    writeRegister(CC2520_FRMFILT0, frmfilt0.value);

    //frmctrl0 = cc2520_frmctrl0_default;
    //frmctrl0.f.autoack = 1;
    //writeRegister(CC2520_FRMCTRL0, frmctrl0.value);

    // accept reserved frames
    frmfilt1 = cc2520_frmfilt1_default;
    frmfilt1.f.accept_ft_4to7_reserved = 1;
    writeRegister(CC2520_FRMFILT1, frmfilt1.value);

    // disable src address decoding
    srcmatch = cc2520_srcmatch_default;
    srcmatch.f.src_match_en = 0;
    writeRegister(CC2520_SRCMATCH, srcmatch.value);

    // enable auto crc and append rssi to frame
    // this is done by default.
  }

  void initRadio(){
    resetRadio();

    atomic first_packet = TRUE;

    txPower = CC2520_DEF_RFPOWER & CC2520_TX_PWR_MASK;
    channel = CC2520_DEF_CHANNEL & CC2520_CHANNEL_MASK;

    state = STATE_PD;
  }

  /*----------------- SPI -----------------*/

  event void SpiResource.granted(){

    if( state == STATE_VR_ON ){
      initRadio();
      call SpiResource.release();
    }else if(state == STATE_RX_DOWNLOAD){
      downloadMessage();
    }else
      call Tasklet.schedule();
  }

  bool isSpiAcquired(){
    if( call SpiResource.isOwner() ){
      return TRUE;
    }

    if( call SpiResource.immediateRequest() == SUCCESS ){
      return TRUE;
    }

    call SpiResource.request();
    return FALSE;
  }

  async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t error) {};

  /*----------------- CHANNEL -----------------*/

  tasklet_async command uint8_t RadioState.getChannel(){
    return channel;
  }

  tasklet_async command error_t RadioState.setChannel(uint8_t c){
    c &= CC2520_CHANNEL_MASK;

    if( cmd != CMD_NONE )
      return EBUSY;
    else if( channel == c )
      return EALREADY;

    channel = c;
    cmd = CMD_CHANNEL;
    call Tasklet.schedule();

    return SUCCESS;
  }

  inline void setChannel(){
    cc2520_freqctrl_t freqctrl;
    // set up freq
    freqctrl = cc2520_freqctrl_default;
    freqctrl.f.freq = 11 + 5 * (channel - 11);
#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      call DiagMsg.str("freqctrl");
      call DiagMsg.uint8(freqctrl.value);
      call DiagMsg.send();
    }
#endif

    writeRegister(CC2520_FREQCTRL, freqctrl.value);
  }

  inline void changeChannel(){
    RADIO_ASSERT( cmd == CMD_CHANNEL );
    RADIO_ASSERT( state == STATE_PD || state == STATE_IDLE || ( state == STATE_RX_ON && call RadioAlarm.isFree()));

    if( isSpiAcquired() ){
      setChannel();

      if( state == STATE_RX_ON ) {
        call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods
        state = STATE_IDLE_2_RX_ON;
      }
      else
        cmd = CMD_SIGNAL_DONE;
    }
  }

  /*----------------- TURN ON/OFF -----------------*/

  inline void changeState(){

    if( (cmd == CMD_STANDBY || cmd == CMD_TURNON)
        && state == STATE_PD  && isSpiAcquired() && call RadioAlarm.isFree() ){

      // start oscillator
      strobe(CC2520_CMD_SXOSCON);

      call RadioAlarm.wait(PD_2_IDLE_TIME); // .86ms OSC startup time
      state = STATE_PD_2_IDLE;
    }
    else if( cmd == CMD_TURNON && state == STATE_IDLE && isSpiAcquired() && call RadioAlarm.isFree()){
      // setChannel was ignored in SLEEP because the SPI was not working, so do it here
      setChannel();

      // start receiving
      strobe(CC2520_CMD_SRXON);
      call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods
      state = STATE_IDLE_2_RX_ON;
    }
    else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY)
        && state == STATE_RX_ON && isSpiAcquired() ){
      // stop receiving
      strobe(CC2520_CMD_SRFOFF);

      state = STATE_IDLE;
    }

    if( cmd == CMD_TURNOFF && state == STATE_IDLE  && isSpiAcquired() ){
      // stop oscillator
      strobe(CC2520_CMD_SXOSCOFF);

      // do a reset
      initRadio();
      state = STATE_PD;
      cmd = CMD_SIGNAL_DONE;
    }
    else if( cmd == CMD_STANDBY && state == STATE_IDLE )
      cmd = CMD_SIGNAL_DONE;
  }

  // TODO: turn off SFD capture when turning off radio
  tasklet_async command error_t RadioState.turnOff(){
    if( cmd != CMD_NONE )
      return EBUSY;
    else if( state == STATE_PD )
      return EALREADY;

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      call DiagMsg.str("turnOff");
      call DiagMsg.send();
    }
#endif

    cmd = CMD_TURNOFF;
    call Tasklet.schedule();

    return SUCCESS;
  }

  tasklet_async command error_t RadioState.standby(){
    if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
      return EBUSY;
    else if( state == STATE_IDLE )
      return EALREADY;

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      call DiagMsg.str("standBy");
      call DiagMsg.send();
    }
#endif

    cmd = CMD_STANDBY;
    call Tasklet.schedule();

    return SUCCESS;
  }

  // TODO: turn on SFD capture when turning off radio
  tasklet_async command error_t RadioState.turnOn(){
    if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
      return EBUSY;
    else if( state == STATE_RX_ON )
      return EALREADY;

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      call DiagMsg.str("turnOn");
      call DiagMsg.send();
    }
#endif

    cmd = CMD_TURNON;
    call Tasklet.schedule();

    return SUCCESS;
  }

  default tasklet_async event void RadioState.done() {}

  /*----------------- TRANSMIT -----------------*/

  tasklet_async command error_t RadioSend.send(message_t* msg){
    uint8_t p;
    uint8_t micLength = 0;
    uint32_t frameCounter;
    cc2520_status_t status;
    security_header_t* secHdr;

    secMode = 0;
    prevdata9 = 0;
    prevdata10 = 0;

    if( cmd != CMD_NONE || (state != STATE_IDLE && state != STATE_RX_ON) || radioIrq || ! isSpiAcquired() )
      return EBUSY;

    p = (call PacketTransmitPower.isSet(msg) ?
        call PacketTransmitPower.get(msg) : CC2520_DEF_RFPOWER) & CC2520_TX_PWR_MASK;

    if( p != txPower ){
      cc2520_txpower_t txpower = cc2520_txpower_default;

      txPower = p;

      txpower.f.pa_power = txPower;
      writeRegister(CC2520_TXPOWER, txpower.value);
    }

#ifdef RADIO_DEBUG_MESSAGES
    {
      uint8_t tmp1, tmp2;
      tmp1 = call Config.requiresRssiCca(msg);
      tmp2 = call CCA.get();
      if( call DiagMsg.record() ){
        call DiagMsg.str("cca");
        call DiagMsg.int8(tmp1);
        call DiagMsg.int8(tmp2);
        call DiagMsg.send();
      }
      if( tmp1 && !tmp2) {
        call SpiResource.release();
        return EBUSY;
      }
    }
#else
    if( call Config.requiresRssiCca(msg) && !call CCA.get() ) {
      call SpiResource.release();
      return EBUSY;
    }
#endif

    // there's a chance that there was a receive SFD interrupt in such a
    // short time.
    // TODO: there's still a chance

    atomic if (call SFD.get() == 1 || radioIrq) {
      call SpiResource.release();
      return EBUSY;
    }
    else
      // stop receiving
      strobe(CC2520_CMD_SRFOFF);

    RADIO_ASSERT( ! radioIrq );

    txData = getPayload(msg);
    txLength = getHeader(msg)->length;

    secMode = call CC2520Security.getSecurityMode();
    txIeee154header = (ieee154_simple_header_t*)txData;

    if(secMode > 0 &&  (txIeee154header->fcf & (IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE))){

      // Note that the payload starts at txData[9] when 16 bit addressing is used
      frameCounter = call CC2520Security.getFrameCounter();
      frameCounter = 0;
      memcpy(&encNonce[3], &frameCounter, 4);

      writeMemory(ADDR_DATA, &txData[11], 2);

      //JK: Set security related parameters
      writeMemory(ADDR_KEY, call CC2520Security.getKey(), 16);
      writeMemory(ADDR_NONCE, encNonce, 16);

      MEMCP(HIGH_PRIORITY, 16, ADDR_KEY, ADDR_KEY);
      MEMCP(HIGH_PRIORITY, 16, ADDR_NONCE, ADDR_NONCE);

      //JK: Send ENC command

      while(security_processing){}

      security_processing = TRUE;

      if(secMode == CTR_MODE){
        micLength = 0;
        CTR(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_NONCE/16, ADDR_DATA, 0); //11 for txData and 2 for fcs
      }else if(secMode == CBC_MAC_4){
        micLength = 4;
        CBCMAC(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_DATA, 0, 1);
      }else if(secMode == CBC_MAC_8){
        micLength = 8;
        CBCMAC(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_DATA, 0, 2);
      }else if(secMode == CBC_MAC_16){
        micLength = 16;
        CBCMAC(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_DATA, 0, 3);
      }else if(secMode == CCM_4){
        micLength = 4;
        CCM(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_NONCE/16, ADDR_DATA, 0, txLength - 11 - 2, 1);
      }else if(secMode == CCM_8){
        micLength = 8;
        CCM(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_NONCE/16, ADDR_DATA, 0, txLength - 11 - 2, 2);
      }else if(secMode == CCM_16){
        micLength = 16;
        CCM(HIGH_PRIORITY, ADDR_KEY/16, txLength - 11 - 2, ADDR_NONCE/16, ADDR_DATA, 0, txLength - 11 - 2, 3);
      }

      status = getStatus();
      while(status.dpu_h_active)
        status = getStatus();

      readMemory(ADDR_DATA, &txData[11+sizeof(security_header_t)], 2 + micLength);

      security_processing = FALSE;

      txData[9+sizeof(security_header_t)] = txData[9];
      txData[10+sizeof(security_header_t)] = txData[10];

      prevdata9 = txData[9];
      prevdata10 = txData[10];

      secHdr = (security_header_t*)&txData[9]; // beginning of txData section

      secHdr->secLevel = secMode;
      secHdr->keyMode = 1; // Fixed to 1 for now
      secHdr->reserved = 0;
      secHdr->frameCounter = frameCounter;
      secHdr->keyID[0] = 1; // Always first position for now due to fixed keyMode

      txIeee154header->fcf |= 1 << IEEE154_FCF_SECURITY_ENABLED;

      txLength += (sizeof(security_header_t) + micLength);

    }

    // txLength | txData[0] ... txData[txLength-3] | automatically generated FCS

    atomic writeTxFifo(&txLength, 1);

    // FCS is automatically generated
    txLength -= 2;

    // preload fcf, dsn, destpan, and dest
    header = call Config.headerPreloadLength();
    if( header > txLength )
      header = txLength;

    txLength -= header;

    // first upload the header to gain some time
    atomic writeTxFifo(txData, header);

    atomic {
      //call SfdCapture.captureRisingEdge();
      strobe(CC2520_CMD_STXON);
      state = STATE_TX_ON;
      //*((volatile uint32_t * )0x40010054) |= (1 << 16);
      call SfdCapture.captureRisingEdge();
    }

    //#ifdef RADIO_DEBUG_MESSAGES
    txMsg = msg;
    //#endif

    // wait for SFD rising edge.
    return SUCCESS;
  }

  inline void continueTx()
  {
    void* timesync;
    uint32_t time32;
    cc2520_status_t status;


    /*****************************************
     * FIXME: We have to check for underrun here!
     *****************************************/

    // prepare for end of TX on falling SFD

    timesync = call PacketTimeSyncOffset.isSet(txMsg) ? ((void*)txMsg) + call PacketTimeSyncOffset.get(txMsg) : 0;

    time32 = capturedTime;

    if( timesync != 0 )
      *(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - time32;

    // write the rest of the payload to the fifo
    atomic writeTxFifo(txData+header, txLength);

    call SfdCapture.captureFallingEdge();

    if(secMode > 0){
      txData[9] = prevdata9;
      txData[10] = prevdata10;
    }

    // get status
    status = getStatus();
    RADIO_ASSERT ( status.tx_active == 1);
    // FIXME: have to check for underflow exception!
    //RADIO_ASSERT ( status.tx_underflow == 0);
    RADIO_ASSERT ( status.xosc_stable == 1);

    if( timesync != 0 )
      *(timesync_absolute_t*)timesync = (*(timesync_relative_t*)timesync) + time32;

    call PacketTimeStamp.set(txMsg, time32);

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      uint16_t t = call RadioAlarm.getNow();
      txLength = getHeader(txMsg)->length;

      call DiagMsg.chr('t');
      call DiagMsg.uint16(time32);
      call DiagMsg.uint16(t);
      call DiagMsg.uint16(t-time32);
      call DiagMsg.uint32(call PacketTimeStamp.isValid(txMsg) ? call PacketTimeStamp.timestamp(txMsg) : 0);
      call DiagMsg.int8(txLength);
      call DiagMsg.hex8s(getPayload(txMsg), txLength - 2);
      if(txLength - 2 > 15) {
        call DiagMsg.hex8s(&(((uint8_t *)getPayload(txMsg))[15]), txLength - 2 - 15);
      }
      if(txIeee154header->fcf & (1 << IEEE154_FCF_ACK_REQ)){
        call DiagMsg.str("w/ ack");
      }

      call DiagMsg.send();
    }
#endif

    // wait for SFD falling edge
    state = STATE_BUSY_TX_2_RX_ON;
    cmd = CMD_TRANSMIT;

    //call SpiResource.release();
    atomic sending = TRUE;
  }

  default tasklet_async event void RadioSend.sendDone(error_t error) { }
  default tasklet_async event void RadioSend.ready() { }

  /*----------------- CCA -----------------*/

  tasklet_async command error_t RadioCCA.request(){
    if( cmd != CMD_NONE || state != STATE_RX_ON )
      return EBUSY;

    if(call CCA.get()) {
      signal RadioCCA.done(SUCCESS);
    } else {
      signal RadioCCA.done(EBUSY);
    }
    return SUCCESS;
  }

  default tasklet_async event void RadioCCA.done(error_t error) { }

  /*----------------- RECEIVE -----------------*/

  // recover from an error
  // rx fifo flush does not always work
  inline void recover() {
    cc2520_status_t status;

    // reset the radio, initialize registers to default values
    RADIO_ASSERT(0);
    resetRadio();

    //call SfdCapture.disable();

    RADIO_ASSERT(state == STATE_PD);

    // start oscillator
    strobe(CC2520_CMD_SXOSCON);

    // going idle in PD_2_IDLE_TIME
    state = STATE_PD_2_IDLE;

    call BusyWait.wait(PD_2_IDLE_TIME); // .86ms OSC startup time

    // get status
    status = getStatus();
    RADIO_ASSERT ( status.rssi_valid == 0);
    //RADIO_ASSERT ( status.lock == 0);
    RADIO_ASSERT ( status.tx_active == 0);
    //RADIO_ASSERT ( status.enc_busy == 0);
    //RADIO_ASSERT ( status.tx_underflow == 0);
    RADIO_ASSERT ( status.xosc_stable == 1);

    // we're idle now
    state = STATE_IDLE;

    // download current channel to the radio
    setChannel();

    // start receiving
    strobe(CC2520_CMD_SRXON);
    state = STATE_IDLE_2_RX_ON;

    //call SfdCapture.captureRisingEdge(); // JK

    // we will be able to receive packets in 12 symbol periods
    state = STATE_RX_ON;
  }

  inline void recover_err() {
    cc2520_status_t status;

    // reset the radio, initialize registers to default values
    RADIO_ASSERT(0);

    resetRadio();
    // start oscillator
    strobe(CC2520_CMD_SXOSCON);

    // going idle in PD_2_IDLE_TIME
    state = STATE_PD_2_IDLE;

    //call BusyWait.wait(PD_2_IDLE_TIME); // .86ms OSC startup time

    // get status
    status = getStatus();
    RADIO_ASSERT ( status.rssi_valid == 0);
    //RADIO_ASSERT ( status.lock == 0);
    RADIO_ASSERT ( status.tx_active == 0);
    //RADIO_ASSERT ( status.enc_busy == 0);
    //RADIO_ASSERT ( status.tx_underflow == 0);
    RADIO_ASSERT ( status.xosc_stable == 1);

    // we're idle now
    state = STATE_IDLE;

    // download current channel to the radio
    setChannel();

    // start receiving
    strobe(CC2520_CMD_SRXON);
    state = STATE_IDLE_2_RX_ON;

    //call SfdCapture.captureRisingEdge(); // JK

    // we will be able to receive packets in 12 symbol periods
    state = STATE_RX_ON;
  }

  inline void endRx(){
    receiving = FALSE;
  }

  inline void downloadMessage(){ // receiving message to buffer!
    uint8_t length, micLength;
    uint16_t crc = 1;
    uint8_t* data;
    uint8_t rssi;
    uint8_t crc_ok_lqi;
    uint32_t sfdTime, decLimit;
    cc2520_status_t status;
    security_header_t* secHdr;
    ieee154_simple_header_t* ieee154header;

    //call Draw.fill(COLOR_WHITE);

    //state = STATE_RX_DOWNLOAD;

    isSpiAcquired();

    atomic sfdTime = capturedTime;

    // data starts after the length field
    data = getPayload(rxMsg);

    // read the length byte
    readLengthFromRxFifo(&length);

#ifdef RADIO_DEBUG_MESSAGES_____
    if( call DiagMsg.record() ){
      call DiagMsg.str("rx");
      call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
      call DiagMsg.uint16(sfdTime);
      call DiagMsg.uint16(call RadioAlarm.getNow());
      call DiagMsg.int8(length);
      call DiagMsg.hex8s(getPayload(rxMsg), length - 2);
      call DiagMsg.send();
    }
#endif
    // check for too short lengths
    if (length == 0) {

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        call DiagMsg.str("rx 0 length");
        call DiagMsg.send();
      }
#endif
      if(!first_packet){
        atomic recover_err();
        atomic flushRxFifo();
      }

      atomic first_packet = FALSE;

      call CSN.set();

      RADIO_ASSERT( call FIFOP.get() == 0 );
      RADIO_ASSERT( call FIFO.get() == 0 );

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    if (length == 1) {
      // skip payload and rssi
      atomic readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);

      RADIO_ASSERT( call FIFOP.get() == 0 );
      RADIO_ASSERT( call FIFO.get() == 0 );

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    if (length == 2) {
      // skip payload
      atomic readRssiFromRxFifo(&rssi);
      atomic readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);

      RADIO_ASSERT( call FIFOP.get() == 0 );
      RADIO_ASSERT( call FIFO.get() == 0 );

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    // check for too long lengths
    if( length > 127 ) {

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        call DiagMsg.str("rx > 127");
        call DiagMsg.send();
      }
#endif
      atomic recover_err();
      atomic flushRxFifo(); // JK

      RADIO_ASSERT( call FIFOP.get() == 0 );
      RADIO_ASSERT( call FIFO.get() == 0 );

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    if( length > call RadioPacket.maxPayloadLength() + 2 ){

      while( length-- > 2 ) {
        atomic readPayloadFromRxFifo(data, 1);
      }

      atomic readRssiFromRxFifo(&rssi);
      atomic readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        call DiagMsg.str("rx too long");
        call DiagMsg.send();
      }
#endif
      atomic recover_err();
      atomic flushRxFifo();

      RADIO_ASSERT( call FIFOP.get() == 0 );

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    // if we're here, length must be correct
    RADIO_ASSERT(length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2);

    getHeader(rxMsg)->length = length;

    // we'll read the FCS/CRC separately
    length -= 2;

    // download the whole payload
    readPayloadFromRxFifo(data, length);

    // the last two bytes are not the fsc, but RSSI(8), CRC_ON(1)+LQI(7)
    readRssiFromRxFifo(&rssi);

    readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);

    ieee154header = (ieee154_simple_header_t*)data;

    // TODO: actually, we can signal that a message was received, without
    // timestamp set

    if (call FIFOP.get() == 1 || call FIFO.get() == 1) {

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        call DiagMsg.str("FIFO or FIFOP = 1");
        call DiagMsg.send();
      }
#endif
      atomic recover_err();
      atomic flushRxFifo();

      call SpiResource.release();
      call CSN.set();
      endRx();
      return;
    }

    if( signal RadioReceive.header(rxMsg) ){
      // set RSSI, CRC and LQI only if we're accepting the message
      call PacketRSSI.set(rxMsg, rssi);
      call PacketLinkQuality.set(rxMsg, crc_ok_lqi & 0x7f);
      crc = (crc_ok_lqi > 0x7f) ? 0 : 1;
    }


    if(length == 3 || ieee154header->fcf & (2 << IEEE154_FCF_FRAME_TYPE) ){
      //call Leds.led2Toggle();
      call SpiResource.release();
      call CSN.set();
      rxMsg = signal RadioReceive.receive(rxMsg);
      endRx();
      return;
    }


    // signal only if it has passed the CRC check
    if( crc == 0){
      call PacketTimeStamp.set(rxMsg, sfdTime);

#ifdef RADIO_DEBUG_MESSAGES
      if( call DiagMsg.record() ){
        uint16_t t = call RadioAlarm.getNow();
        call DiagMsg.chr('r');
        //call DiagMsg.uint16(call RadioAlarm.getNow() - (uint16_t)call PacketTimeStamp.timestamp(rxMsg) );
        call DiagMsg.uint16(sfdTime);
        call DiagMsg.uint16(t);
        call DiagMsg.uint16(t-sfdTime);
        call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
        call DiagMsg.int8(length);
        call DiagMsg.hex8s(getPayload(rxMsg), length);
        if(length > 15) {
          call DiagMsg.hex8s(&(((uint8_t*)getPayload(rxMsg))[15]), length - 15);
        }
        call DiagMsg.send();
      }
#endif

      // check fcf for security bit in data packets
      if((ieee154header->fcf & (1 << IEEE154_FCF_SECURITY_ENABLED)) && (ieee154header->fcf & (IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE))  ){

        secHdr = (security_header_t*)&data[9];
        memcpy(&decNonce[3], &(secHdr->frameCounter), 4); // readout nonce from tinyos 15.4 security header

        writeMemory(ADDR_KEY, call CC2520Security.getKey(), 16);
        writeMemory(ADDR_NONCE, decNonce, 16);

        MEMCP(HIGH_PRIORITY, 16, ADDR_KEY, ADDR_KEY);
        MEMCP(HIGH_PRIORITY, 16, ADDR_NONCE, ADDR_NONCE); // reverse twice since CC2420 uses the correct ordered nonce

        // TODO: add proper operation for each case

        atomic security_processing = TRUE;

        // perform security options.
        if (secHdr->secLevel == NO_SEC){
          micLength = 0;
        }else if (secHdr->secLevel == CBC_MAC_4){
          micLength = 4;
        }else if (secHdr->secLevel == CBC_MAC_8){
          micLength = 8;
        }else if (secHdr->secLevel == CBC_MAC_16){
          micLength = 16;
        }else if (secHdr->secLevel == CTR_MODE){
          writeMemory(ADDR_DATA, &data[11+sizeof(security_header_t)], length - sizeof(security_header_t) - 11);
          CTR(HIGH_PRIORITY, ADDR_KEY/16, length - sizeof(security_header_t) - 11, ADDR_NONCE/16, ADDR_DATA, 0);
          //mode = CC2420_CTR;
          micLength = 0;
        }else if (secHdr->secLevel == CCM_4){
          micLength = 4;
        }else if (secHdr->secLevel == CCM_8){
          micLength = 8;
        }else if (secHdr->secLevel == CCM_16){
          micLength = 16;
        }else{
          // invalid security
          micLength = 0;
        }

        // Wait for security done interrupt (pp. 49)
        status = getStatus();
        decLimit = 0;

        while(status.dpu_h_active && decLimit++ < 0xFFFF)
	  status = getStatus();

	call Leds.led0Toggle();

        // copy data from the memory to msg buffer and delete security header
        data[9] = data[9+sizeof(security_header_t)];
        data[10] = data[10+sizeof(security_header_t)];
        readMemory(ADDR_DATA, &data[11], length - 11 - sizeof(security_header_t));

        atomic security_processing = FALSE;

        length = length - micLength - sizeof(security_header_t); // TODO: not working out too well
        // TODO: If I do this do I lose the RSSI pointers?


        //readMemory(ADDR_DATA, &data[11+sizeof(security_header_t)], length - 11 - sizeof(security_header_t));
        //length -= micLength;
        //memcpy(&data[9], &data[9+sizeof(security_header_t)], 2 + (length - 11 - sizeof(security_header_t)));
        //length -= micLength - sizeof(security_header_t); // modify length w.r.t. mic length

      }

      call SpiResource.release();
      call CSN.set();

      call Leds.led1Toggle();
      rxMsg = signal RadioReceive.receive(rxMsg);
      endRx();

      // ready to receive new message: enable SFD interrupts
      //call SfdCapture.captureRisingEdge(); // JK

    }else{
      call SpiResource.release();
      call CSN.set();
      //state = STATE_RX_ON;
      //cmd = CMD_NONE;

      //call Draw.drawInt(80,140,5,1,COLOR_BLUE);
      endRx();
      // ready to receive new message: enable SFD interrupts
      //call SfdCapture.captureRisingEdge();// JK
    }
  }


  /*----------------- IRQ -----------------*/

  // SFD (rising edge) for timestamps in RX & TX, falling for TX end
  async event void SfdCapture.captured( uint16_t time )  {

    //call SfdCapture.disable();
    // if canceling the above takes care of the stopping issue, then
    //the state machine is getting stck at some point inthe disable
    //state

    RADIO_ASSERT( ! radioIrq );
    RADIO_ASSERT( state == STATE_RX_ON || state == STATE_TX_ON || state == STATE_BUSY_TX_2_RX_ON );

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() ){
      call DiagMsg.str("SFD");
      call DiagMsg.uint16(time);
      call DiagMsg.uint16(call RadioAlarm.getNow());
      call DiagMsg.str("s=");
      call DiagMsg.uint8(state);
      if(call FIFO.get())
        call DiagMsg.str("FIFO");
      if(call FIFOP.get())
        call DiagMsg.str("FIFOP");
      if(call SFD.get())
        call DiagMsg.str("SFD");

      call DiagMsg.send();
    }
#endif

    if(call SFD.get())
    {
      atomic {
        // rising edge, safe time and mutex to 0
        capturedTime = call LocalTime.get();
        // FIXME: there is a small chance that between the SFD and read of
        // LocalTime, the timer overflowed. This wil incurr an error of 65436.
        // We have to check for this overflow! But how?
        if(state == STATE_TX_ON)
        {
          if((uint16_t)(time + TX_SFD_DELAY) > (uint16_t)(capturedTime))
            // we had an overflow between SFD capture and read of LocalTime
            capturedTime -= 1<<16;
          capturedTime += (uint16_t)(time + TX_SFD_DELAY) - (uint16_t)(capturedTime);
        } else {
          if((uint16_t)(time - RX_SFD_DELAY) > (uint16_t)(capturedTime))
            // we had an overflow between SFD capture and read of LocalTime
            capturedTime -= 1<<16;
          capturedTime += (uint16_t)(time - RX_SFD_DELAY) - (uint16_t)(capturedTime);
        }
      }
    }
    radioIrq = TRUE;
    call Tasklet.schedule();
  }

  async event void FifoInterrupt.fired(){
  }

  // FIFOP interrupt, last byte received
  async event void FifopInterrupt.fired(){
    if(receiving == FALSE){
      atomic receiving = TRUE;
      downloadMessage();
    }
  }

  inline void serviceRadio(){
    atomic if( isSpiAcquired() ){
      radioIrq = FALSE;
      switch(state)
      {
        case STATE_TX_ON:
          continueTx();
          break;

        case STATE_BUSY_TX_2_RX_ON:
          state = STATE_RX_ON;
          cmd = CMD_NONE;
          if(sending){
            atomic sending = FALSE;
            call SfdCapture.captureRisingEdge(); // JK release this to enable rx side sfd.
            // do not signal success if the packet requested for an ack
            // In this case call a timer instead and signal success once the timer expires or an ack is received
            call Leds.led2Toggle();

#ifdef RADIO_DEBUG_MESSAGES
	    if( call DiagMsg.record() ){
	      call DiagMsg.str("RadioSend.sendDone");
	      call DiagMsg.send();
	    }
#endif
	    signal RadioSend.sendDone(SUCCESS);


          }

        default:
          RADIO_ASSERT(1);
      }
    }
  }


default tasklet_async event bool RadioReceive.header(message_t* msg){
  return TRUE;
}

default tasklet_async event message_t* RadioReceive.receive(message_t* msg){
  return msg;
}



/*----------------- TASKLET -----------------*/

tasklet_async event void Tasklet.run(){

  if( radioIrq ){
    serviceRadio();
  }

  if( cmd != CMD_NONE ){
    if( cmd == CMD_DOWNLOAD && state == STATE_RX_ON){ // receive state
      //downloadMessage();
    }
    else if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
      changeState();
    else if( cmd == CMD_CHANNEL )
      changeChannel();

    if( cmd == CMD_SIGNAL_DONE ){
      cmd = CMD_NONE;
      signal RadioState.done();
    }
  }

  if( cmd == CMD_NONE && state == STATE_RX_ON && ! radioIrq )
    signal RadioSend.ready();

  if( cmd == CMD_NONE )
    call SpiResource.release();
}

/*----------------- RadioPacket -----------------*/

async command uint8_t RadioPacket.headerLength(message_t* msg){
  return call Config.headerLength(msg) + sizeof(cc2520_header_t);
}

async command uint8_t RadioPacket.payloadLength(message_t* msg){
  return getHeader(msg)->length - 2;
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length){
  RADIO_ASSERT( 1 <= length && length <= 125 );
  RADIO_ASSERT( call RadioPacket.headerLength(msg) + length + call RadioPacket.metadataLength(msg) <= sizeof(message_t) );

  // we add the length of the CRC, which is automatically generated
  getHeader(msg)->length = length + 2;
}

async command uint8_t RadioPacket.maxPayloadLength(){
  RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(cc2520_header_t) <= 125 );

  return call Config.maxPayloadLength() - sizeof(cc2520_header_t);
}

async command uint8_t RadioPacket.metadataLength(message_t* msg){
  return call Config.metadataLength(msg) + sizeof(cc2520_metadata_t);
}

async command void RadioPacket.clear(message_t* msg){
  // all flags are automatically cleared
}

/*----------------- PacketTransmitPower -----------------*/

async command bool PacketTransmitPower.isSet(message_t* msg){
  return call TransmitPowerFlag.get(msg);
}

async command uint8_t PacketTransmitPower.get(message_t* msg){
  return getMeta(msg)->power;
}

async command void PacketTransmitPower.clear(message_t* msg){
  call TransmitPowerFlag.clear(msg);
}

async command void PacketTransmitPower.set(message_t* msg, uint8_t value){
  call TransmitPowerFlag.set(msg);
  getMeta(msg)->power = value;
}

/*----------------- PacketRSSI -----------------*/

async command bool PacketRSSI.isSet(message_t* msg)
{
  return call RSSIFlag.get(msg);
}

async command uint8_t PacketRSSI.get(message_t* msg)
{
  return getMeta(msg)->rssi;
}

async command void PacketRSSI.clear(message_t* msg)
{
  call RSSIFlag.clear(msg);
}

async command void PacketRSSI.set(message_t* msg, uint8_t value)
{
  // just to be safe if the user fails to clear the packet
  call TransmitPowerFlag.clear(msg);

  call RSSIFlag.set(msg);
  getMeta(msg)->rssi = value;
}

/*----------------- PacketTimeSyncOffset -----------------*/

async command bool PacketTimeSyncOffset.isSet(message_t* msg)
{
  return call TimeSyncFlag.get(msg);
}

async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
{
  return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
}

async command void PacketTimeSyncOffset.clear(message_t* msg)
{
  call TimeSyncFlag.clear(msg);
}

async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value)
{
  // we do not store the value, the time sync field is always the last 4 bytes
  RADIO_ASSERT( call PacketTimeSyncOffset.get(msg) == value );

  call TimeSyncFlag.set(msg);
}

/*----------------- PacketLinkQuality -----------------*/

async command bool PacketLinkQuality.isSet(message_t* msg)
{
  return TRUE;
}

async command uint8_t PacketLinkQuality.get(message_t* msg)
{
  return getMeta(msg)->lqi;
}

async command void PacketLinkQuality.clear(message_t* msg)
{
}

async command void PacketLinkQuality.set(message_t* msg, uint8_t value)
{
  getMeta(msg)->lqi = value;
}

ieee154_simple_header_t* getIeeeHeader(message_t* msg)
{
  return (ieee154_simple_header_t*) (void*)msg;//getHeader(msg);//((void*)msg) + call SubPacket.headerLength(msg);
}

async command error_t PacketAcknowledgements.requestAck(message_t* msg)
{
  //call SoftwareAckConfig.setAckRequired(msg, TRUE);
  getIeeeHeader(msg)->fcf |= (1 << IEEE154_FCF_ACK_REQ);

  return SUCCESS;
}

async command error_t PacketAcknowledgements.noAck(message_t* msg)
{
  getIeeeHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_ACK_REQ);
  return SUCCESS;
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg)
{
#ifdef CC2520_HARDWARE_ACK
  return call AckReceivedFlag.get(msg);
#else
  RADIO_ASSERT(1);
  return FALSE;
#endif
}



}
