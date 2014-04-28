/*
* Copyright (c) 2007, Vanderbilt University
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Miklos Maroti
* Author:Andras Biro
*/

#include <RFA1DriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>

module RFA1DriverLayerP
{
  provides
  {
    interface Init as PlatformInit @exactlyonce();
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
    interface LinkPacketMetadata;

    interface McuPowerOverride;
  }

  uses
  {
    interface BusyWait<TMicro, uint16_t>;
    interface LocalTime<TRadio>;
    interface HplAtmegaCapture<uint32_t> as SfdCapture;

    interface RFA1DriverConfig as Config;

    interface PacketFlag as TransmitPowerFlag;
    interface PacketFlag as RSSIFlag;
    interface PacketFlag as TimeSyncFlag;

    interface PacketTimeStamp<TRadio, uint32_t>;

    interface Tasklet;
    interface McuPowerState;
    interface AsyncStdControl as ExtAmpControl;

#ifdef RADIO_DEBUG
    interface DiagMsg;
#endif
  }
}

implementation
{
  rfa1_header_t* getHeader(message_t* msg)
  {
    return ((void*)msg) + call Config.headerLength(msg);
  }

  void* getPayload(message_t* msg)
  {
    return ((void*)msg) + call RadioPacket.headerLength(msg);
  }

  rfa1_metadata_t* getMeta(message_t* msg)
  {
    return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
  }

  /*----------------- STATE -----------------*/

  tasklet_norace uint8_t state;
  enum
  {
    STATE_P_ON = 0,
    STATE_SLEEP = 1,
    STATE_SLEEP_2_TRX_OFF = 2,
    STATE_TRX_OFF = 3,
    STATE_TRX_OFF_2_RX_ON = 4,
    STATE_RX_ON = 5,
    STATE_BUSY_TX_2_RX_ON = 6,
  };

  tasklet_norace uint8_t cmd;
  enum
  {
    CMD_NONE = 0,    // the state machine has stopped
    CMD_TURNOFF = 1,    // goto SLEEP state
    CMD_STANDBY = 2,    // goto TRX_OFF state
    CMD_TURNON = 3,    // goto RX_ON state
    CMD_TRANSMIT = 4,    // currently transmitting a message
    CMD_RECEIVE = 5,    // currently receiving a message
    CMD_CCA = 6,    // performing clear channel assessment
    CMD_CHANNEL = 7,    // changing the channel
    CMD_SIGNAL_DONE = 8,  // signal the end of the state transition
    CMD_DOWNLOAD = 9,    // download the received message
  };

  enum {
    IRQ_NONE=0,
    IRQ_AWAKE=1,
    IRQ_TX_END=2,
    IRQ_XAH_AMI=4,
    IRQ_CCA_ED_DONE=8,
    IRQ_RX_END=16,
    IRQ_RX_START=32,
    IRQ_PLL_UNLOCK=64,
    IRQ_PLL_LOCK=128,
  };

  enum {
    // this disables the RFA1RadioOffP component
    RFA1RADIOON = unique("RFA1RadioOn"),
  };

  norace uint8_t radioIrq;

  tasklet_norace uint8_t txPower;
  tasklet_norace uint8_t channel;

  tasklet_norace message_t* rxMsg;
  message_t rxMsgBuffer;

  tasklet_norace uint8_t rssiClear;
  tasklet_norace uint8_t rssiBusy;

  /*----------------- INIT -----------------*/

  command error_t PlatformInit.init()
  {
    rxMsg = &rxMsgBuffer;

    // these are just good approximates
    rssiClear = 0;
    rssiBusy = 90;

    return SUCCESS;
  }

  command error_t SoftwareInit.init()
  {
    CCA_THRES=RFA1_CCA_THRES_VALUE;

#ifdef RFA1_ENABLE_PA
    SET_BIT(DDRG,0);	// DIG3
    CLR_BIT(PORTG,0);
    SET_BIT(DDRF, 3);	// DIG0
    CLR_BIT(PORTF, 3);
#endif
#ifdef RFA1_ENABLE_EXT_ANT_SW
    SET_BIT(DDRG, 1);// DIG1
    CLR_BIT(PORTG,1);
    SET_BIT(DDRF, 2); // DIG2
    CLR_BIT(PORTF, 2);
#endif
#ifdef RFA1_DATA_RATE
    #if RFA1_DATA_RATE == 250
      TRX_CTRL_2 = (TRX_CTRL_2 & 0xfc) | 0;
    #elif RFA1_DATA_RATE == 500
      TRX_CTRL_2 = (TRX_CTRL_2 & 0xfc) | 1;
    #elif RFA1_DATA_RATE == 1000
      TRX_CTRL_2 = (TRX_CTRL_2 & 0xfc) | 2;
    #elif RFA1_DATA_RATE == 2000
      TRX_CTRL_2 = (TRX_CTRL_2 & 0xfc) | 3;
    #else
      #error Unsupported RFA1_DATA_RATE (supported: 250, 500, 1000, 2000. default is 250)
    #endif
#endif
    PHY_TX_PWR = RFA1_PA_BUF_LT | RFA1_PA_LT | (RFA1_DEF_RFPOWER&RFA1_TX_PWR_MASK)<<TX_PWR0;

    txPower = RFA1_DEF_RFPOWER & RFA1_TX_PWR_MASK;
    channel = RFA1_DEF_CHANNEL & RFA1_CHANNEL_MASK;
    TRX_CTRL_1 |= 1<<TX_AUTO_CRC_ON;
    PHY_CC_CCA = RFA1_CCA_MODE_VALUE | channel;

    SET_BIT(TRXPR,SLPTR);

    call SfdCapture.setMode(ATMRFA1_CAPSC_ON);

    state = STATE_SLEEP;

    return SUCCESS;
  }

  /*----------------- CHANNEL -----------------*/

  tasklet_async command uint8_t RadioState.getChannel()
  {
    return channel;
  }

  tasklet_async command error_t RadioState.setChannel(uint8_t c)
  {
    c &= RFA1_CHANNEL_MASK;

    if( cmd != CMD_NONE )
      return EBUSY;
    else if( channel == c )
      return EALREADY;

    channel = c;
    cmd = CMD_CHANNEL;
    call Tasklet.schedule();

    return SUCCESS;
  }

  inline void changeChannel()
  {
    RADIO_ASSERT( cmd == CMD_CHANNEL );
    RADIO_ASSERT( state == STATE_SLEEP || state == STATE_TRX_OFF || state == STATE_RX_ON );

    if( state != STATE_SLEEP )
      PHY_CC_CCA=RFA1_CCA_MODE_VALUE|channel;

    if( state == STATE_RX_ON )
      state = STATE_TRX_OFF_2_RX_ON;
    else
      cmd = CMD_SIGNAL_DONE;
  }

  /*----------------- TURN ON/OFF -----------------*/

  inline void changeState()
  {
    if( (cmd == CMD_STANDBY || cmd == CMD_TURNON) && state == STATE_SLEEP )
    {
      RADIO_ASSERT( ! radioIrq );

      IRQ_STATUS = 0xFF;
      IRQ_MASK = 1<<AWAKE_EN;
      CLR_BIT(TRXPR,SLPTR);
      call McuPowerState.update();

      state = STATE_SLEEP_2_TRX_OFF;
    }
    else if( cmd == CMD_TURNON && state == STATE_TRX_OFF )
    {
      RADIO_ASSERT( ! radioIrq );
      
      // setChannel was ignored in SLEEP because the register didn't work
      PHY_CC_CCA=RFA1_CCA_MODE_VALUE|channel;

      IRQ_MASK = 1<<PLL_LOCK_EN | 1<<TX_END_EN | 1<<RX_END_EN | 1<< RX_START_EN | 1<<CCA_ED_DONE_EN;
      call McuPowerState.update();

      TRX_STATE = CMD_RX_ON;
#ifdef RFA1_ENABLE_PA
      SET_BIT(TRX_CTRL_1, PA_EXT_EN);
#endif
#ifdef RFA1_ENABLE_EXT_ANT_SW
      #ifdef RFA1_ANT_DIV_EN
      ANT_DIV = 0x7f & (1<<ANT_DIV_EN | 1<<ANT_EXT_SW_EN);
      #elif defined(RFA1_ANT_SEL1)
      ANT_DIV = 0x7f & (1<<ANT_EXT_SW_EN | 1<<ANT_CTRL0);
      #elif defined(RFA1_ANT_SEL0)
      ANT_DIV = 0x7f & (1<<ANT_EXT_SW_EN | 2<<ANT_CTRL0);
      #else
      #error Neighter antenna is selected with ANT_EXT_SW_EN. You can choose between RFA1_ANT_DIV_EN, RFA1_ANT_SEL0, RFA1_ANT_SEL1
      #endif
#endif
      state = STATE_TRX_OFF_2_RX_ON;
      call ExtAmpControl.start();
    }
    else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) && state == STATE_RX_ON )
    {
#ifdef RFA1_ENABLE_PA
      CLR_BIT(TRX_CTRL_1, PA_EXT_EN);
#endif
#ifdef RFA1_ENABLE_EXT_ANT_SW
      ANT_DIV=3; //default value
#endif
      TRX_STATE = CMD_FORCE_TRX_OFF;

      IRQ_MASK = 0;
      radioIrq = IRQ_NONE;

      call McuPowerState.update();

      state = STATE_TRX_OFF;
      call ExtAmpControl.stop();
    }

    if( cmd == CMD_TURNOFF && state == STATE_TRX_OFF )
    {
      SET_BIT(TRXPR,SLPTR);
      state = STATE_SLEEP;
      cmd = CMD_SIGNAL_DONE;
    }
    else if( cmd == CMD_STANDBY && state == STATE_TRX_OFF )
    {
      IRQ_MASK = 0;
      call McuPowerState.update();

      cmd = CMD_SIGNAL_DONE;
    }
  }

  tasklet_async command error_t RadioState.turnOff()
  {
    if( cmd != CMD_NONE )
      return EBUSY;
    else if( state == STATE_SLEEP )
      return EALREADY;

    cmd = CMD_TURNOFF;
    call Tasklet.schedule();

    return SUCCESS;
  }

  tasklet_async command error_t RadioState.standby()
  {
    if( cmd != CMD_NONE  )
      return EBUSY;
    else if( state == STATE_TRX_OFF )
      return EALREADY;

    cmd = CMD_STANDBY;
    call Tasklet.schedule();

    return SUCCESS;
  }

  tasklet_async command error_t RadioState.turnOn()
  {
    if( cmd != CMD_NONE )
      return EBUSY;
    else if( state == STATE_RX_ON )
      return EALREADY;
    cmd = CMD_TURNON;
    call Tasklet.schedule();

    return SUCCESS;
  }

  default tasklet_async event void RadioState.done() { }

  /*----------------- TRANSMIT -----------------*/

  enum {
    // 16 us delay (1 tick), 4 bytes preamble (2 ticks each), 1 byte SFD (2 ticks)
    TX_SFD_DELAY = 11,
  };

  tasklet_async command error_t RadioSend.send(message_t* msg)
  {
    uint32_t time;
    uint8_t length;
    uint8_t* data;
    void* timesync;

    if( cmd != CMD_NONE || state != STATE_RX_ON || radioIrq )
      return EBUSY;

    length = (call PacketTransmitPower.isSet(msg) ?
        call PacketTransmitPower.get(msg) : RFA1_DEF_RFPOWER) & RFA1_TX_PWR_MASK;

    if( length != txPower )
    {
      txPower = length;
      PHY_TX_PWR=RFA1_PA_BUF_LT | RFA1_PA_LT | txPower<<TX_PWR0;
    }

    if( call Config.requiresRssiCca(msg)
          && (PHY_RSSI & RFA1_RSSI_MASK) > ((rssiClear + rssiBusy) >> 3) )
      return EBUSY;

    TRX_STATE = CMD_PLL_ON;

    // do something useful, just to wait a little
    timesync = call PacketTimeSyncOffset.isSet(msg) ? ((void*)msg) + call PacketTimeSyncOffset.get(msg) : 0;

    data = getPayload(msg);
    length = getHeader(msg)->length;

    // length | data[0] ... data[length-3] | automatically generated FCS
    TRXFBST = length;

    // the FCS is atomatically generated (2 bytes) (TX_AUTO_CRC_ON==1 by default)
    length -= 2;

    // we have missed an incoming message in this short amount of time
    if( (TRX_STATUS & RFA1_TRX_STATUS_MASK) != PLL_ON )
    {
      RADIO_ASSERT( (TRX_STATUS & RFA1_TRX_STATUS_MASK) == BUSY_RX );

      TRX_STATE = CMD_RX_ON;
      return EBUSY;
    }

    atomic
    {
        time = call LocalTime.get();
        TRX_STATE = CMD_TX_START;
    }

    time += TX_SFD_DELAY;

    RADIO_ASSERT( ! radioIrq );

    // fix the time stamp
    if( timesync != 0 )
      *(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - time;

    // then upload the whole payload
    memcpy((void*)(&TRXFBST+1), data, length);

    // go back to RX_ON state when finished
    TRX_STATE=CMD_RX_ON;

    if( timesync != 0 )
      *(timesync_absolute_t*)timesync = (*(timesync_relative_t*)timesync) + time;

    call PacketTimeStamp.set(msg, time);

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() )
    {
      length = getHeader(msg)->length;

      call DiagMsg.chr('t');
      call DiagMsg.uint32(call PacketTimeStamp.isValid(msg) ? call PacketTimeStamp.timestamp(msg) : 0);
      call DiagMsg.uint16(call LocalTime.get());
      call DiagMsg.int8(length);
      call DiagMsg.hex8s(getPayload(msg), length - 2);
      call DiagMsg.send();
    }
#endif

    // wait for the TRX_END interrupt
    state = STATE_BUSY_TX_2_RX_ON;
    cmd = CMD_TRANSMIT;

    return SUCCESS;
  }

  default tasklet_async event void RadioSend.sendDone(error_t error) { }
  default tasklet_async event void RadioSend.ready() { }

  /*----------------- CCA -----------------*/

  tasklet_async command error_t RadioCCA.request()
  {
    if( cmd != CMD_NONE || state != STATE_RX_ON )
      return EBUSY;

    // see Errata 38.5.5 datasheet
    TRX_STATE=CMD_PLL_ON;
    //TODO: test&optimize this
    call BusyWait.wait(1);
    if( (TRX_STATUS & RFA1_TRX_STATUS_MASK) != PLL_ON )
        return EBUSY;
    SET_BIT(RX_SYN,RX_PDT_DIS);
    TRX_STATE=CMD_RX_ON;
    //end of workaround

    cmd = CMD_CCA;
    PHY_CC_CCA = 1 << CCA_REQUEST | RFA1_CCA_MODE_VALUE | channel;

    return SUCCESS;
  }

  default tasklet_async event void RadioCCA.done(error_t error) { }

  /*----------------- RECEIVE -----------------*/

  //TODO: RX_SAFE_MODE with define
  inline void downloadMessage()
  {
    uint8_t length;
    bool sendSignal = FALSE;

    length = TST_RX_LENGTH;

    if( (PHY_RSSI & (1<<RX_CRC_VALID)) && length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2 )
    {
      uint8_t* data;

      data = getPayload(rxMsg);
      getHeader(rxMsg)->length = length;

      // we do not store the CRC field
      length -= 2;

      // memory is fast, no point optimizing header check
      memcpy(data,(void*)&TRXFBST,length);

      if( signal RadioReceive.header(rxMsg) )
      {
        call PacketLinkQuality.set(rxMsg, (uint8_t)*(&TRXFBST+TST_RX_LENGTH));
        sendSignal = TRUE;
      }
    }

    state = STATE_RX_ON;

#ifdef RADIO_DEBUG_MESSAGES
    if( call DiagMsg.record() )
    {
      length = getHeader(rxMsg)->length;

      call DiagMsg.chr('r');
      call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
      call DiagMsg.uint16(call LocalTime.get());
      call DiagMsg.int8(sendSignal ? length : -length);
      call DiagMsg.hex8s(getPayload(rxMsg), length - 2);
      call DiagMsg.int8(call PacketRSSI.isSet(rxMsg) ? call PacketRSSI.get(rxMsg) : -1);
      call DiagMsg.uint8(call PacketLinkQuality.isSet(rxMsg) ? call PacketLinkQuality.get(rxMsg) : 0);
      call DiagMsg.send();
    }
#endif

    cmd = CMD_NONE;

    // signal only if it has passed the CRC check
    if( sendSignal )
      rxMsg = signal RadioReceive.receive(rxMsg);
  }

  default tasklet_async event bool RadioReceive.header(message_t* msg)
  {
    return TRUE;
  }

  default tasklet_async event message_t* RadioReceive.receive(message_t* msg)
  {
    return msg;
  }

  /*----------------- IRQ -----------------*/

  void serviceRadio()
  {
    uint32_t time;
    uint8_t irq;
    uint8_t temp;

    atomic
    {
      time = call SfdCapture.get();
      irq = radioIrq;
      radioIrq = IRQ_NONE;
    }

#ifdef RFA1_RSSI_ENERGY
    // check this early before the PHY_ED_LEVEL register is overwritten
    if( irq == IRQ_RX_END )
      call PacketRSSI.set(rxMsg, PHY_ED_LEVEL);
    else
      call PacketRSSI.clear(rxMsg);
#endif

    if( (irq & IRQ_PLL_LOCK) != 0 )
    {
      if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
      {
        RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );

        state = STATE_RX_ON;
        cmd = CMD_SIGNAL_DONE;
      }
      else if( cmd == CMD_TRANSMIT )
        RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );
      else
        RADIO_ASSERT(FALSE);
    }

    if( cmd == CMD_TRANSMIT && (irq & IRQ_TX_END) != 0 )
    {
      RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );

      state = STATE_RX_ON;
      cmd = CMD_NONE;
      signal RadioSend.sendDone(SUCCESS);

      // TODO: we could have missed a received message
      RADIO_ASSERT( ! (irq & IRQ_RX_START) );
    }

    if( (irq & IRQ_RX_START) != 0 )
    {
      if( cmd == CMD_CCA )
      {
        signal RadioCCA.done(FAIL);
        cmd = CMD_NONE;
      }

      if( cmd == CMD_NONE )
      {
        RADIO_ASSERT( state == STATE_RX_ON );

        // the most likely place for busy channel and good SFD, with no other interrupts
        if( irq == IRQ_RX_START )
        {
          temp = PHY_RSSI & RFA1_RSSI_MASK;
          rssiBusy += temp - (rssiBusy >> 2);

          call PacketTimeStamp.set(rxMsg, time);

#ifndef RFA1_RSSI_ENERGY
          call PacketRSSI.set(rxMsg, temp);
#endif
        }
        else
        {
          call PacketTimeStamp.clear(rxMsg);

#ifndef RFA1_RSSI_ENERGY
          call PacketRSSI.clear(rxMsg);
#endif
        }

        cmd = CMD_RECEIVE;
      }
      else
        RADIO_ASSERT( cmd == CMD_TURNOFF );
    }

    if( cmd == CMD_RECEIVE && (irq & IRQ_RX_END) != 0 )
    {
      RADIO_ASSERT( state == STATE_RX_ON );

      // the most likely place for clear channel (hope to avoid acks)
      rssiClear += (PHY_RSSI & RFA1_RSSI_MASK) - (rssiClear >> 2);

      cmd = CMD_DOWNLOAD;
    }

    if( (irq & IRQ_AWAKE) != 0 ){
      if( state == STATE_SLEEP_2_TRX_OFF && (cmd==CMD_STANDBY || cmd==CMD_TURNON) )
        state = STATE_TRX_OFF;
      else
        RADIO_ASSERT(FALSE);
    }

    if( (irq & IRQ_CCA_ED_DONE) != 0 ){
      if( cmd == CMD_CCA )
      {
        // workaround, see Errata 38.5.5 datasheet
        CLR_BIT(RX_SYN,RX_PDT_DIS);

        cmd = CMD_NONE;

        RADIO_ASSERT( state == STATE_RX_ON );
        RADIO_ASSERT( (TRX_STATUS & RFA1_TRX_STATUS_MASK) == RX_ON );

        signal RadioCCA.done( (TRX_STATUS & CCA_DONE) ? ((TRX_STATUS & CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
      }
      else
        RADIO_ASSERT(FALSE);
    }
  }

  /**
   * Indicates the completion of a frame transmission
   */
  AVR_NONATOMIC_HANDLER(TRX24_TX_END_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_TX_END;
    call Tasklet.schedule();
  }

  /**
   * Indicates the completion of a frame reception
   */
  AVR_NONATOMIC_HANDLER(TRX24_RX_END_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_RX_END;
    call Tasklet.schedule();
  }

  /**
   * Indicates the start of a PSDU reception. The TRX_STATE changes
   * to BUSY_RX, the PHR is ready to be read from Frame Buffer
   */
  AVR_NONATOMIC_HANDLER(TRX24_RX_START_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_RX_START;
    call Tasklet.schedule();
  }

  /**
   * Indicates PLL lock
   */
  AVR_NONATOMIC_HANDLER(TRX24_PLL_LOCK_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_PLL_LOCK;
    call Tasklet.schedule();
  }

  /**
   * indicates sleep/reset->trx_off mode change
   */
  AVR_NONATOMIC_HANDLER(TRX24_AWAKE_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_AWAKE;
    call Tasklet.schedule();
  }

  /**
   * indicates CCA ED done
   */
  AVR_NONATOMIC_HANDLER(TRX24_CCA_ED_DONE_vect){
    RADIO_ASSERT( ! radioIrq );

    atomic radioIrq |= IRQ_CCA_ED_DONE;
    call Tasklet.schedule();
  }

  // never called, we have the RX_START interrupt instead
  async event void SfdCapture.fired() { }

  /*----------------- TASKLET -----------------*/

  tasklet_async event void Tasklet.run()
  {
    if( radioIrq != IRQ_NONE )
      serviceRadio();

    if( cmd != CMD_NONE )
    {
      if( cmd == CMD_DOWNLOAD )
        downloadMessage();
      else if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
        changeState();
      else if( cmd == CMD_CHANNEL )
        changeChannel();

      if( cmd == CMD_SIGNAL_DONE )
      {
        cmd = CMD_NONE;
        signal RadioState.done();
      }
    }

    if( cmd == CMD_NONE && state == STATE_RX_ON && ! radioIrq )
      signal RadioSend.ready();

  }

  /*----------------- McuPower -----------------*/

   async command mcu_power_t McuPowerOverride.lowestState()
   {
      if( (IRQ_MASK & 1<<AWAKE_EN) != 0 )
         return ATM128_POWER_EXT_STANDBY;
      else
         return ATM128_POWER_DOWN;
   }

  /*----------------- RadioPacket -----------------*/

  async command uint8_t RadioPacket.headerLength(message_t* msg)
  {

    return call Config.headerLength(msg) + sizeof(rfa1_header_t);
  }

  async command uint8_t RadioPacket.payloadLength(message_t* msg)
  {
    return getHeader(msg)->length - 2;
  }

  async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
  {
    RADIO_ASSERT( 1 <= length && length <= 125 );
    RADIO_ASSERT( call RadioPacket.headerLength(msg) + length + call RadioPacket.metadataLength(msg) <= sizeof(message_t) );
    // we add the length of the CRC, which is automatically generated
    getHeader(msg)->length = length + 2;
  }

  async command uint8_t RadioPacket.maxPayloadLength()
  {
    RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(rfa1_header_t) <= 125 );

    return call Config.maxPayloadLength() - sizeof(rfa1_header_t);
  }

  async command uint8_t RadioPacket.metadataLength(message_t* msg)
  {
    return call Config.metadataLength(msg) + sizeof(rfa1_metadata_t);
  }

  async command void RadioPacket.clear(message_t* msg)
  {
    // all flags are automatically cleared
  }

  /*----------------- PacketTransmitPower -----------------*/

  async command bool PacketTransmitPower.isSet(message_t* msg)
  {
    return call TransmitPowerFlag.get(msg);
  }

  async command uint8_t PacketTransmitPower.get(message_t* msg)
  {
    return getMeta(msg)->power;
  }

  async command void PacketTransmitPower.clear(message_t* msg)
  {
    call TransmitPowerFlag.clear(msg);
  }

  async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
  {
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

/*----------------- LinkPacketMetadata -----------------*/

  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg)
  {
    return call PacketLinkQuality.get(msg) > 200;
  }

/*----------------- ExtAmpControl -----------------*/

  default async command error_t ExtAmpControl.start(){
    return SUCCESS;
  }

  default async command error_t ExtAmpControl.stop(){
    return SUCCESS;
  }
}
