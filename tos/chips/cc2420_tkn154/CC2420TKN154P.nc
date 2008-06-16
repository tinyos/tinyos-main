/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:02:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
#include <CC2420.h>
#include "Timer62500hz.h"

module CC2420TKN154P 
{

  provides {
    interface SplitControl;
    interface RadioRx;
    interface RadioTx;
    interface RadioOff;
    interface EnergyDetection;
    interface Set<bool> as RadioPromiscuousMode;
    interface Timestamp;
  } uses {
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface LocalTime<T62500hz> as LocalTime;
    interface Resource as SpiResource;
    interface AsyncStdControl as TxControl;        
    interface CC2420AsyncSplitControl as RxControl; 
    interface CC2420Power;
    interface CC2420Config;
    interface CC2420Rx;
    interface CC2420Tx;
    interface Random;
    interface Leds;
    interface ReliableWait;
    interface ReferenceTime;
    interface TimeCalc;
  }

} implementation {

  typedef enum {
    S_STOPPED,
    S_STOPPING,
    S_STARTING,

    S_RADIO_OFF,
    S_ED,

    S_RESERVE_RX_SPI,
    S_RX_PREPARED,
    S_RECEIVING,
    S_OFF_PENDING,

    S_LOAD_TXFIFO,
    S_TX_LOADED,
    S_TX_ACTIVE,
    S_TX_CANCEL,
    S_TX_DONE,
  } m_state_t;

  norace m_state_t m_state = S_STOPPED;
  norace ieee154_txframe_t *m_txdata;
  norace error_t m_txError;
  norace ieee154_reftime_t m_txReferenceTime;
  norace bool m_ackFramePending;
  uint32_t m_edDuration;
  bool m_pibUpdated;
  uint8_t m_numCCA;
  ieee154_reftime_t *m_t0Tx;
  uint32_t m_dtTx;

  norace uint8_t m_txLockOnCCAFail;
  norace bool m_rxAfterTx = FALSE;
  norace bool m_stop = FALSE;

  task void startDoneTask();
  task void rxControlStopDoneTask();
  task void stopTask();

  uint8_t dBmToPA_LEVEL(int dbm);
  void txDoneRxControlStopped();
  void rxSpiReserved();
  void txSpiReserved();
  void txDoneSpiReserved();
  void signalTxDone();
  void finishTx();
  void stopContinue();
  void offSpiReserved();
  void offStopRxDone();
  void continueTxPrepare();
  

  /******************************/
  /* StdControl Operations      */
  /******************************/

  /****************************************/
  /*     TelosB Pin connection (debug)    */
  /*                                      */
  /* R1 = P6.6 = ADC6, R2 = P6.7 = ADC7   */
  /* S1 = P2.3 = GIO2, S2 = P2.6 = GIO3   */
  /* R1 is at 6pin-expansion pin 1,       */               
  /* R2 is at 6pin-expansion pin 2,       */               
  /****************************************/

  command error_t SplitControl.start()
  {
    // debug
    //P6SEL &= ~0xC0;     // debug PIN: 6.6, 6.7, set to I/O function
    //P6DIR |= 0xC0;      // output
    //P6OUT &= ~0xC0;     // low
    
    atomic {
      if (m_state == S_RADIO_OFF)
        return EALREADY;
      else {
        if (m_state != S_STOPPED)
          return FAIL;
        m_state = S_STARTING;
      }
    }
    return call SpiResource.request();
  }

  void startReserved()
  {
    call CC2420Power.startVReg();
  }

  async event void CC2420Power.startVRegDone() 
  {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() 
  {
    // default configuration (addresses, etc) has been written
    call CC2420Power.rfOff();
    call CC2420Tx.unlockChipSpi();
    post startDoneTask();
  }

  task void startDoneTask() 
  {
    call CC2420Config.setChannel(IEEE154_DEFAULT_CURRENTCHANNEL);
    call CC2420Config.setShortAddr(IEEE154_DEFAULT_SHORTADDRESS);
    call CC2420Config.setPanAddr(IEEE154_DEFAULT_PANID);
    call CC2420Config.setPanCoordinator(FALSE);  
    call CC2420Config.setPromiscuousMode(FALSE);
    call CC2420Config.setCCAMode(IEEE154_DEFAULT_CCAMODE);
    call CC2420Config.setTxPower(dBmToPA_LEVEL(IEEE154_DEFAULT_TRANSMITPOWER_dBm));
    call CC2420Config.sync();
    call SpiResource.release();
    m_stop = FALSE;
    m_state = S_RADIO_OFF;
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop() 
  {
    atomic {
      if (m_state == S_STOPPED)
        return EALREADY;
    }
    post stopTask();
    return SUCCESS;
  }

  task void stopTask()
  {
    atomic {
      if (m_state == S_RADIO_OFF)
        m_state = S_STOPPING;
    }
    if (m_state != S_STOPPING)
      post stopTask(); // this will not happen, because the caller has switched radio off
    else 
      if (call RxControl.stop() == EALREADY)
        stopContinue();
  }

  void stopContinue()
  {
    call SpiResource.request();
  }

  void stopReserved()
  {
    // we own the SPI bus
    atomic {
      call CC2420Power.rfOff();
      call CC2420Tx.unlockChipSpi();
      call TxControl.stop();
      call CC2420Power.stopOscillator(); 
      call CC2420Power.stopVReg();
      call SpiResource.release();
      m_state  = S_STOPPED;
      signal SplitControl.stopDone(SUCCESS);
    }
  }

  /*********************************/
  /*  PIB Updates                  */
  /*********************************/
  
  // input: power in dBm, output: PA_LEVEL parameter for cc2420 TXCTRL register
  uint8_t dBmToPA_LEVEL(int dBm)
  {
    uint8_t result;
    // the cc2420 has 8 discrete (documented) values - we take the closest
    if (dBm >= 0)
      result = 31;
    else if (dBm > -2)
      result = 27;
    else if (dBm > -4)
      result = 23;
    else if (dBm > -6)
      result = 19;
    else if (dBm > -9)
      result = 15;
    else if (dBm > -13)
      result = 11;
    else if (dBm > -20)
      result = 7;
    else
      result = 3;
    return result;
  }

  event void PIBUpdate.notify[uint8_t PIBAttribute](const void* PIBAttributeValue)
  {
    uint8_t txpower;
    switch (PIBAttribute)
    {
      case IEEE154_macShortAddress:
        call CC2420Config.setShortAddr(*((ieee154_macShortAddress_t*) PIBAttributeValue));
        break;
      case IEEE154_macPANId:
        call CC2420Config.setPanAddr(*((ieee154_macPANId_t*) PIBAttributeValue));
        break;
      case IEEE154_phyCurrentChannel:
        call CC2420Config.setChannel(*((ieee154_phyCurrentChannel_t*) PIBAttributeValue));
        break;
      case IEEE154_macPanCoordinator:
        call CC2420Config.setPanCoordinator(*((ieee154_macPanCoordinator_t*) PIBAttributeValue));
        break;
      case IEEE154_phyTransmitPower:
        // lower 6 bits are twos-complement in dBm (range -32..+31 dBm)
        txpower = (*((ieee154_phyTransmitPower_t*) PIBAttributeValue)) & 0x3F;
        if (txpower & 0x20)
          txpower |= 0xC0; // make it negative, to be interpreted as int8_t
        call CC2420Config.setTxPower(dBmToPA_LEVEL((int8_t) txpower));
        break;
      case IEEE154_phyCCAMode:
        call CC2420Config.setCCAMode(*((ieee154_phyCCAMode_t*) PIBAttributeValue));
        break;
    }
  }

  command void RadioPromiscuousMode.set( bool val )
  {
    call CC2420Config.setPromiscuousMode(val);
  }

  /*********************************/
  /* Energy Detection              */
  /*********************************/

  command error_t EnergyDetection.start(uint32_t duration)
  {
    error_t status = FAIL;
    atomic {
      if (m_state == S_RADIO_OFF){
        m_state = S_ED;
        m_edDuration = duration;
        status = SUCCESS;
      }
    }
    if (status == SUCCESS)
      call SpiResource.request(); // we will not give up the SPI until we're done
    return status;
  }

  void edReserved()
  {
    int8_t value, maxEnergy = -128;
    uint32_t start = call LocalTime.get();
    call CC2420Config.sync(); // put PIB changes into operation (if any)
    call CC2420Power.rxOn();
    // reading an RSSI value over SPI will usually almost
    // take as much time as 8 symbols, i.e. there's 
    // no point using an Alarm here (but maybe a BusyWait?)
    while (!call TimeCalc.hasExpired(start, m_edDuration)){
      if (call CC2420Power.rssi(&value) != SUCCESS)
        continue;
      if (value > maxEnergy)
        maxEnergy = value;
    }
    // P = RSSI_VAL + RSSI_OFFSET [dBm] 
    // RSSI_OFFSET is approximately -45.
    if (maxEnergy > -128)
      maxEnergy -= 45; 
    call CC2420Power.rfOff();
    m_state = S_RADIO_OFF;
    call SpiResource.release();
    signal EnergyDetection.done(SUCCESS, maxEnergy);
  }

  /****************************************/
  /*     Transceiver Off                  */
  /****************************************/

  async command error_t RadioOff.off()
  {
    atomic {
      if (m_state == S_RADIO_OFF)
        return EALREADY;
      else if (m_state != S_RECEIVING && m_state != S_TX_LOADED && m_state != S_RX_PREPARED)
        return FAIL;
      m_state = S_OFF_PENDING;
    }
    call SpiResource.release(); // may fail
    if (call RxControl.stop() == EALREADY) // will trigger offStopRxDone()
      offStopRxDone();
    return SUCCESS;
  }
  
  void offStopRxDone()
  {
    if (call SpiResource.immediateRequest() == SUCCESS)
      offSpiReserved();
    else
      call SpiResource.request();  // will trigger offSpiReserved()
  }

  void offSpiReserved()
  {
    call TxControl.stop();
    call CC2420Power.rfOff();
    call CC2420Config.sync(); // put any PIB updates into operation
    call CC2420Tx.unlockChipSpi();
    call SpiResource.release();
    m_state = S_RADIO_OFF;
    signal RadioOff.offDone();
  }

  async command bool RadioOff.isOff()
  {
    return m_state == S_RADIO_OFF;
  }

  /****************************************/
  /*     Receive Operations               */
  /****************************************/

  async command error_t RadioRx.prepare()
  {
    atomic {
      if (call RadioRx.isPrepared())
        return EALREADY;
      else if (m_state != S_RADIO_OFF)
        return FAIL;
      m_state = S_RESERVE_RX_SPI;
    }
    if (call RxControl.start() != SUCCESS){  // will trigger rxStartRxDone()
      m_state = S_RADIO_OFF;
      call Leds.led0On();
      return FAIL; 
    }
    return SUCCESS; 
  }

  void rxStartRxDone()
  {
    if (call SpiResource.immediateRequest() == SUCCESS)   // will trigger rxSpiReserved()
      rxSpiReserved();
    else
      call SpiResource.request();
  }

  void rxSpiReserved()
  {
    call CC2420Config.sync(); // put PIB changes into operation
    call TxControl.start();   // for timestamping
    m_state = S_RX_PREPARED;
    signal RadioRx.prepareDone(); // keep owning the SPI
  }

  async command bool RadioRx.isPrepared()
  { 
    return m_state == S_RX_PREPARED;
  }

  async command error_t RadioRx.receive(ieee154_reftime_t *t0, uint32_t dt)
  {
    atomic {
      if (m_state != S_RX_PREPARED){
        call Leds.led0On();
        return FAIL;
      }
      if (t0 != NULL && dt)
        call ReliableWait.waitRx(t0, dt);
      else
        signal ReliableWait.waitRxDone();
    }
    return SUCCESS;
  }

  async event void ReliableWait.waitRxDone()
  {
    atomic {
      if (call CC2420Power.rxOn() != SUCCESS)
        call Leds.led0On();
      m_state = S_RECEIVING;
    }
    call CC2420Tx.lockChipSpi();
    call SpiResource.release();    
  }

  event message_t* CC2420Rx.received(message_t *data, ieee154_reftime_t *timestamp) 
  {
    if (m_state == S_RECEIVING)
      return signal RadioRx.received(data, timestamp);
    else
      return data;
  }

  async command bool RadioRx.isReceiving()
  { 
    return m_state == S_RECEIVING;
  }

  /******************************/
  /*     Transmit Operations    */
  /******************************/

  async command error_t RadioTx.load(ieee154_txframe_t *frame)
  {
    bool startRxControl;
    atomic {
      if (m_state != S_RADIO_OFF && m_state != S_TX_LOADED)
        return FAIL;
      startRxControl = (m_state == S_RADIO_OFF);
      m_txdata = frame;
      m_state = S_LOAD_TXFIFO;
    }
    if (!startRxControl)
      continueTxPrepare();
    else if (call RxControl.start() != SUCCESS) // will trigger continueTxPrepare()
      call Leds.led0On();
    return SUCCESS;
  }

  void continueTxPrepare()
  {
    if (call SpiResource.immediateRequest() == SUCCESS) 
      txSpiReserved();
    else
      call SpiResource.request(); // will trigger txSpiReserved()
  }

  void txSpiReserved()
  {
    call CC2420Config.sync();
    call TxControl.start();
    if (call CC2420Tx.loadTXFIFO(m_txdata) != SUCCESS)
      call Leds.led0On();
  }

  async event void CC2420Tx.loadTXFIFODone(ieee154_txframe_t *data, error_t error)
  {
    if (m_state != S_LOAD_TXFIFO || error != SUCCESS)
      call Leds.led0On();
    m_state = S_TX_LOADED;
    signal RadioTx.loadDone();  // we keep owning the SPI
  }

  async command ieee154_txframe_t* RadioTx.getLoadedFrame()
  {
    if (m_state == S_TX_LOADED)
     return m_txdata;
    else 
      return NULL;
  }

  async command error_t RadioTx.transmit(ieee154_reftime_t *t0, uint32_t dt, uint8_t numCCA, bool ackRequest)
  {
    atomic {
      if (m_state != S_TX_LOADED)
        return FAIL;
      m_numCCA = numCCA;
      m_t0Tx = t0;
      m_dtTx = dt;
      if (numCCA){
        // for CCA we need to be in Rx mode
        call CC2420Power.rxOn();
        call ReliableWait.busyWait(20); // turnaround + CCA valid time
        if (numCCA == 2){
          // first CCA is done in software (8 symbols after backoff boundary)
          if (t0 != NULL){
            call ReliableWait.waitCCA(t0, dt-IEEE154_aUnitBackoffPeriod-12);
            return SUCCESS;
          }
        }
      }
      signal ReliableWait.waitCCADone();
    }
    return SUCCESS;
  }

  async event void ReliableWait.waitCCADone()
  {
    bool cca = call CC2420Tx.cca();
    if (m_numCCA == 2 && !cca){
      // channel is busy
      ieee154_reftime_t now;
      call ReferenceTime.getNow(&now, IEEE154_aUnitBackoffPeriod+12);
      memcpy(&m_txReferenceTime, &now, sizeof(ieee154_reftime_t));
      m_ackFramePending = FALSE;
      m_txError = EBUSY;
      signalTxDone();
      return;
    } else {
      // the second CCA (or first CCA if there's only one) is done in hardware...
      uint16_t offset = 0;
      if (m_numCCA)
        offset = 12;
      if (m_t0Tx)
        call ReliableWait.waitTx(m_t0Tx, m_dtTx-offset);
      else
        signal ReliableWait.waitTxDone();
    }
  }

  async event void ReliableWait.waitTxDone()
  {
    m_state = S_TX_ACTIVE;
    call CC2420Tx.send(m_numCCA>0); // go (with or without CCA) !
  }

  async event void CC2420Tx.transmissionStarted( ieee154_txframe_t *data )
  {
    uint8_t frameType = data->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = data->headerLen;
    signal Timestamp.transmissionStarted(frameType, data->handle, data->payload, token);
  }

  async event void CC2420Tx.transmittedSFD(uint32_t time, ieee154_txframe_t *data)
  {
    uint8_t frameType = data->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = data->headerLen;
    signal Timestamp.transmittedSFD(time, frameType, data->handle, data->payload, token);
    // ATTENTION: here we release the SPI, so we can receive a possible ACK
    call SpiResource.release();
  }

  async command void Timestamp.modifyMACPayload(uint8_t token, uint8_t offset, uint8_t* buf, uint8_t len )
  {
    if (m_state == S_TX_ACTIVE)
      call CC2420Tx.modify(offset+1+token, buf, len);
  }

  async event void CC2420Tx.sendDone(ieee154_txframe_t *frame, ieee154_reftime_t *referenceTime, 
      bool ackPendingFlag, error_t error)
  {
    memcpy(&m_txReferenceTime, referenceTime, sizeof(ieee154_reftime_t));
    m_ackFramePending = ackPendingFlag;
    m_txError = error;
    if (error == EBUSY) // CCA failure, i.e. didn't transmit
      signalTxDone();
    else 
      // reset radio
      if (call RxControl.stop() != SUCCESS) // will trigger txDoneRxControlStopped()
        call Leds.led0On();
  }

  void txDoneRxControlStopped()
  {
    // get SPI to switch radio off
    if (call SpiResource.isOwner() || call SpiResource.immediateRequest() == SUCCESS) 
      txDoneSpiReserved();
    else
      call SpiResource.request(); // will trigger txDoneSpiReserved()
  }

  void txDoneSpiReserved() 
  { 
    // switch radio off
    call CC2420Power.rfOff(); 
    call TxControl.stop();
    call SpiResource.release(); // for RxControl.start to succeed
    if (m_txError == SUCCESS)
      signalTxDone();
    else {
      call TxControl.start();
      call RxControl.start(); // will trigger txDoneRxControlStarted()
    }
  }

  void txDoneRxControlStarted()
  {
    m_state = S_TX_DONE;
    call SpiResource.request(); // will trigger signalTxDone()
  }

  void signalTxDone() 
  { 
    // radio is off, Rx component is started, radio is loaded, we own the SPI
    if (m_txError == SUCCESS)
      m_state = S_RADIO_OFF;
    else
      m_state = S_TX_LOADED;
    signal RadioTx.transmitDone(m_txdata, &m_txReferenceTime, m_ackFramePending, m_txError);
  }

  /*************/
  /* RxControl */
  /*************/

  async event void RxControl.stopDone(error_t error)
  {
    post rxControlStopDoneTask();
  }

  task void rxControlStopDoneTask()
  {
    if (m_stop && m_state != S_STOPPING)
      return;
    switch (m_state)
    {
      case S_OFF_PENDING: offStopRxDone(); break;
      case S_RX_PREPARED: rxStartRxDone(); break;
      case S_TX_ACTIVE: txDoneRxControlStopped(); break;
      case S_STOPPING: stopContinue(); break;            
      default: // huh ?
           call Leds.led0On(); break;
    }
  }

  async event void RxControl.startDone(error_t error)
  {
    switch (m_state)
    {
      case S_RESERVE_RX_SPI: rxStartRxDone(); break;
      case S_LOAD_TXFIFO: continueTxPrepare(); break;
      case S_TX_ACTIVE: txDoneRxControlStarted(); break;
      default: // huh ?
           call Leds.led0On(); break;
    }
  }

  /***********************/
  /* SPI Bus Arbitration */
  /***********************/

  event void SpiResource.granted() 
  {
    switch (m_state)
    {
      case S_STARTING: startReserved(); break;
      case S_ED: edReserved(); break;
      case S_RESERVE_RX_SPI: rxSpiReserved(); break;
      case S_LOAD_TXFIFO: txSpiReserved(); break;
      case S_TX_ACTIVE: txDoneSpiReserved(); break;
      case S_STOPPING: stopReserved(); break;
      case S_TX_DONE: signalTxDone(); break;
      case S_OFF_PENDING: offSpiReserved(); break;
      default: // huh ?
           call Leds.led0On(); break;
    }
  }


  default event void SplitControl.startDone(error_t error){}
  default event void SplitControl.stopDone(error_t error){}
  default async event void Timestamp.transmissionStarted(uint8_t frameType, uint8_t msduHandle, uint8_t *msdu, uint8_t token){}
  default async event void Timestamp.transmittedSFD(uint32_t time, uint8_t frameType, uint8_t msduHandle, uint8_t *msdu, uint8_t token){}
}

