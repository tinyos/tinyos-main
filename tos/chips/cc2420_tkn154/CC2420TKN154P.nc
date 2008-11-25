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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:08 $
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
    S_RX_WAIT,
    S_RECEIVING,
    S_OFF_PENDING,

    S_LOAD_TXFIFO,
    S_TX_LOADED,
    S_TX_WAIT,
    S_TX_ACTIVE,
    S_TX_CANCEL,
    S_TX_DONE,
  } m_state_t;

  norace m_state_t m_state = S_STOPPED;
  norace ieee154_txframe_t *m_txframe;
  norace error_t m_txError;
  norace ieee154_reftime_t m_txReferenceTime;
  norace bool m_ackFramePending;
  uint32_t m_edDuration;
  bool m_pibUpdated;
  norace uint8_t m_numCCA;
  ieee154_reftime_t *m_t0Tx;
  uint32_t m_dtMax;
  uint32_t m_dt;
  norace ieee154_csma_t *m_csmaParams;

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
  void finishTx();
  void stopContinue();
  void offSpiReserved();
  void offStopRxDone();
  uint16_t generateRandomBackoff(uint8_t BE);
  void randomDelayUnslottedCsmaCa();
  void randomDelaySlottedCsmaCa(bool resume, uint16_t remainingBackoff);
  void sendDone(ieee154_reftime_t *referenceTime, bool ackPendingFlag, error_t error);
  

/* ----------------------- StdControl Operations ----------------------- */

  command error_t SplitControl.start()
  {
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
    call CC2420Power.flushRxFifo();
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
      post stopTask(); // spin - this should not happen, because the caller has switched radio off
    else 
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
      call CC2420Power.flushRxFifo();
      call CC2420Power.stopOscillator(); 
      call CC2420Power.stopVReg();
      call CC2420Tx.unlockChipSpi();
      call SpiResource.release();
      m_state  = S_STOPPED;
      signal SplitControl.stopDone(SUCCESS);
    }
  }

  uint16_t generateRandomBackoff(uint8_t BE)
  {
    // return random number from [0,(2^BE) - 1] (uniform distr.)
    uint16_t res = call Random.rand16();
    uint16_t mask = 0xFFFF;
    mask <<= BE;
    mask = ~mask;
    res &= mask;
    return res;
  }

/* ----------------------- PIB Updates ----------------------- */
  
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

/* ----------------------- Energy Detection ----------------------- */

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
    // no point using an Alarm here (but maybe a busy wait?)
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
    call CC2420Power.flushRxFifo();
    m_state = S_RADIO_OFF;
    call SpiResource.release();
    signal EnergyDetection.done(SUCCESS, maxEnergy);
  }

/* ----------------------- Transceiver Off ----------------------- */

  task void spinOffTask()
  {
    uint8_t i;
      call Leds.led2On(); call Leds.led1On(); 
      for (i=0; i<65500U; i++) ;
      call Leds.led2Off(); call Leds.led1Off(); 
      for (i=0; i<65500U; i++) ;
    call RadioOff.off();
  }

  async command error_t RadioOff.off()
  {
    atomic {
      if (m_state == S_RADIO_OFF)
        return EALREADY;
      if (m_state == S_RX_WAIT || m_state == S_TX_WAIT){
        post spinOffTask();
        return SUCCESS;
      } else if (m_state != S_RECEIVING && m_state != S_TX_LOADED && m_state != S_RX_PREPARED)
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
    call CC2420Power.flushRxFifo();
    call CC2420Tx.unlockChipSpi();
    call SpiResource.release();
    m_state = S_RADIO_OFF;
    signal RadioOff.offDone();
  }

  async command bool RadioOff.isOff()
  {
    return m_state == S_RADIO_OFF;
  }

/* ----------------------- Receive Operations ----------------------- */

  async command error_t RadioRx.prepare()
  {
    atomic {
      if (call RadioRx.isPrepared())
        return EALREADY;
      else if (m_state != S_RADIO_OFF)
        return FAIL;
      m_state = S_RESERVE_RX_SPI;
    }
    if (call RxControl.start() != SUCCESS){
      m_state = S_RADIO_OFF;
      call Leds.led0On();
      return FAIL; 
    } else {
      if (call SpiResource.immediateRequest() == SUCCESS)   // will trigger rxSpiReserved()
        rxSpiReserved();
      else
        call SpiResource.request();
    }
    return SUCCESS; 
  }

  void rxSpiReserved()
  {
    call CC2420Config.sync(); // put PIB changes into operation
    call TxControl.stop();    
    call TxControl.start();   // for timestamping (SFD interrupt)
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
      m_state = S_RX_WAIT;
      if (t0 != NULL)
        call ReliableWait.waitRx(t0, dt); // will signal waitRxDone() in time
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

  event message_t* CC2420Rx.received(message_t *frame, ieee154_reftime_t *timestamp) 
  {
    if (m_state == S_RECEIVING)
      return signal RadioRx.received(frame, timestamp);
    else
      return frame;
  }

  async command bool RadioRx.isReceiving()
  { 
    return m_state == S_RECEIVING;
  }

/* ----------------------- Transmit Operations ----------------------- */

  async command error_t RadioTx.load(ieee154_txframe_t *frame)
  {
    atomic {
      if (m_state != S_RADIO_OFF && m_state != S_TX_LOADED)
        return FAIL;
      m_txframe = frame;
      m_state = S_LOAD_TXFIFO;
    }
    if (call SpiResource.isOwner() || call SpiResource.immediateRequest() == SUCCESS) 
      txSpiReserved();
    else
      call SpiResource.request(); // will trigger txSpiReserved()
    return SUCCESS;
  }

  void txSpiReserved()
  {
    call CC2420Config.sync();
    call TxControl.start();
    if (call CC2420Tx.loadTXFIFO(m_txframe) != SUCCESS)
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
     return m_txframe;
    else 
      return NULL;
  }

  async command error_t RadioTx.transmit(ieee154_reftime_t *t0, uint32_t dt)
  {
    // transmit without CCA
    atomic {
      if (m_state != S_TX_LOADED)
        return FAIL;
      m_numCCA = 0;
      m_state = S_TX_WAIT;
      if (t0 != NULL)
        call ReliableWait.waitTx(t0, dt); // will signal waitTxDone() in time
      else
        signal ReliableWait.waitTxDone();
    }
    return SUCCESS;
  }

  void checkEnableRxForACK()
  {
    // the packet is currently being transmitted, check if we need the receive logic ready
    bool ackRequest = (m_txframe->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST) ? TRUE : FALSE;
    if (ackRequest){
      // ATTENTION: here the SpiResource is released if ACK is expected
      // (so Rx part of the driver can take over)
      call SpiResource.release();
      if (call RxControl.start() != SUCCESS)
        call Leds.led0On();
    }
  }

  async event void ReliableWait.waitTxDone()
  {
    atomic {
      m_state = S_TX_ACTIVE;
      if (call CC2420Tx.send(FALSE) == SUCCESS) // transmit without CCA, this must succeed
        checkEnableRxForACK();
      else
        call Leds.led0On();
    }
  }

  async command error_t RadioTx.transmitUnslottedCsmaCa(ieee154_csma_t *csmaParams)
  {
    // transmit with single CCA
    atomic {
      if (m_state != S_TX_LOADED)
        return FAIL;
      m_csmaParams = csmaParams;
      m_numCCA = 1;
      randomDelayUnslottedCsmaCa(); 
    }
    return SUCCESS;
  }

  void randomDelayUnslottedCsmaCa()
  {
    // wait random delay (unslotted CSMA-CA)
    uint16_t dtTx = generateRandomBackoff(m_csmaParams->BE) * 20; 
    call ReferenceTime.getNow(m_t0Tx, 0);
    m_state = S_TX_WAIT;
    call ReliableWait.waitBackoff(m_t0Tx, dtTx); 
  }

  void waitBackoffUnslottedCsmaCaDone()
  {
    int8_t dummy;
    atomic {
      // CC2420 needs to be in an Rx state for STXONCCA strobe
      // note: the receive logic of the CC2420 driver is not yet started, 
      // i.e. we will not (yet) receive any packets
      call CC2420Power.rxOn();
      m_state = S_TX_ACTIVE;
      // wait for CC2420 Rx to calibrate + CCA valid time
      while (call CC2420Power.rssi(&dummy) != SUCCESS)
        ;
      // call ReliableWait.busyWait(40);
      // transmit with single CCA (STXONCCA strobe)
      if (call CC2420Tx.send(TRUE) == SUCCESS){
        checkEnableRxForACK();
      } else {
        // channel is busy
        call CC2420Power.rfOff();
        call CC2420Power.flushRxFifo(); // we might have (accidentally) caught something during CCA
        m_state = S_TX_LOADED;
        m_csmaParams->NB += 1;
        if (m_csmaParams->NB > m_csmaParams->macMaxCsmaBackoffs){
          // CSMA-CA failure, note: we keep owning the SPI, 
          // our state is back to S_TX_LOADED, the MAC may try to retransmit
          signal RadioTx.transmitUnslottedCsmaCaDone(m_txframe, FALSE, m_csmaParams, FAIL);
        } else {
          // next iteration of unslotted CSMA-CA
          m_csmaParams->BE += 1;
          if (m_csmaParams->BE > m_csmaParams->macMaxBE)
            m_csmaParams->BE = m_csmaParams->macMaxBE;
          randomDelayUnslottedCsmaCa();
        }
      }
    }
  }

  async command error_t RadioTx.transmitSlottedCsmaCa(ieee154_reftime_t *slot0Time, uint32_t dtMax, 
      bool resume, uint16_t remainingBackoff, ieee154_csma_t *csmaParams)
  {
    // slotted CSMA-CA requires very exact timing (transmission on
    // 320 us backoff boundary), even if we have a sufficiently precise and 
    // accurate clock the CC2420 is not the right radio for
    // this task because it is accessed over SPI. The code below relies on
    // platform-specific busy-wait functions that must be adjusted
    // (through measurements) such that they meet the timing constraints
    atomic {
      if (m_state != S_TX_LOADED)
        return FAIL;
      m_csmaParams = csmaParams;
      m_numCCA = 2;
      m_t0Tx = slot0Time;
      m_dtMax = dtMax;
      randomDelaySlottedCsmaCa(resume, remainingBackoff);
    }
    return SUCCESS;
  }

  void randomDelaySlottedCsmaCa(bool resume, uint16_t remainingBackoff)
  {
    uint16_t dtTx;
    atomic {
      dtTx = call TimeCalc.timeElapsed(call ReferenceTime.toLocalTime(m_t0Tx), call LocalTime.get());
      dtTx += (20 - (dtTx % 20)); // round to backoff boundary
      if (resume)
        dtTx += remainingBackoff;
      else
        dtTx = dtTx + (generateRandomBackoff(m_csmaParams->BE) * 20);
      dtTx += 40; // two backoff periods for the two CCA, the actual tx is scheduled for = m_t0Tx + dtTx
      if (dtTx > m_dtMax){
        uint16_t remaining = dtTx - m_dtMax;
        if (remaining >= 40)
          remaining -= 40; // substract the two CCA (they don't count for the backoff)
        else
          remaining = 0;
        signal RadioTx.transmitSlottedCsmaCaDone(m_txframe, NULL, FALSE, remaining, m_csmaParams, ERETRY);
      } else {
        m_state = S_TX_WAIT;
        call ReliableWait.waitBackoff(m_t0Tx, dtTx); 
      }
    }
  }

  void waitBackoffSlottedCsmaCaDone()
  {
    bool cca;
    uint16_t dtTx=0;
    int8_t dummy;
    atomic {
      // CC2420 needs to be in an Rx state for STXONCCA strobe
      // note: the receive logic of the CC2420 driver is not yet started, 
      // i.e. we will not (yet) receive any packets
      call CC2420Power.rxOn();
      m_state = S_TX_ACTIVE;
      // wait for CC2420 Rx to calibrate + CCA valid time
      while (call CC2420Power.rssi(&dummy) != SUCCESS)
        ;
      // perform CCA on slot boundary (or rather 8 symbols after)
      call ReliableWait.busyWaitSlotBoundaryCCA(m_t0Tx, &dtTx); // platform-specific implementation
      cca = call CC2420Tx.cca();
      if (cca && dtTx <= m_dtMax){
        // Tx in following slot (STXONCCA) 
        call ReliableWait.busyWaitSlotBoundaryTx(m_t0Tx, dtTx+20);  // platform-specific implementation
        if (call CC2420Tx.send(TRUE) == SUCCESS){
          checkEnableRxForACK();
          return;
        } else
          cca = FALSE;
      }
      // did not transmit the frame
      call CC2420Power.rfOff();
      call CC2420Power.flushRxFifo(); // we might have (accidentally) caught something
      m_state = S_TX_LOADED;
      if (dtTx > m_dtMax)
        // frame didn't fit into remaining CAP, this can only
        // be because we couldn't meet the time-constraints 
        // (in principle the frame should have fitted)
        signal RadioTx.transmitSlottedCsmaCaDone(m_txframe, NULL, FALSE, 0, m_csmaParams, ERETRY);
      else {
        // CCA failed
        m_csmaParams->NB += 1;
        if (m_csmaParams->NB > m_csmaParams->macMaxCsmaBackoffs){
          // CSMA-CA failure, note: we keep owning the SPI
          signal RadioTx.transmitSlottedCsmaCaDone(m_txframe, NULL, FALSE, 0, m_csmaParams, FAIL);
        } else {
          // next iteration of slotted CSMA-CA
          m_csmaParams->BE += 1;
          if (m_csmaParams->BE > m_csmaParams->macMaxBE)
            m_csmaParams->BE = m_csmaParams->macMaxBE;
          randomDelaySlottedCsmaCa(FALSE, 0);
        }
      }
    }
  }

  async event void ReliableWait.waitBackoffDone()
  {
    if (m_numCCA == 1)
      waitBackoffUnslottedCsmaCaDone();
    else
      waitBackoffSlottedCsmaCaDone();
  }

  async event void CC2420Tx.transmissionStarted( ieee154_txframe_t *frame )
  {
    uint8_t frameType = frame->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = frame->headerLen;
    signal Timestamp.transmissionStarted(frameType, frame->handle, frame->payload, token);
  }

  async event void CC2420Tx.transmittedSFD(uint32_t time, ieee154_txframe_t *frame)
  {
    uint8_t frameType = frame->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = frame->headerLen;
    signal Timestamp.transmittedSFD(time, frameType, frame->handle, frame->payload, token);
  }

  async command void Timestamp.modifyMACPayload(uint8_t token, uint8_t offset, uint8_t* buf, uint8_t len )
  {
    if (m_state == S_TX_ACTIVE)
      call CC2420Tx.modify(offset+1+token, buf, len);
  }

  async event void CC2420Tx.sendDone(ieee154_txframe_t *frame, ieee154_reftime_t *referenceTime, 
      bool ackPendingFlag, error_t error)
  {
    if (!call SpiResource.isOwner()){
      // this can only happen if an ack was requested and we gave up the SPI
      bool wasAckRequested = (frame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST) ? TRUE : FALSE;
      if (!wasAckRequested)
        call Leds.led0On(); // internal error!
      memcpy(&m_txReferenceTime, referenceTime, sizeof(ieee154_reftime_t));
      m_ackFramePending = ackPendingFlag;
      m_txError = error;
      if (call RxControl.stop() != SUCCESS) // will trigger txDoneRxControlStopped()
        call Leds.led0On();
    } else
      sendDone(referenceTime, ackPendingFlag, error);
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
    sendDone(&m_txReferenceTime, m_ackFramePending, m_txError);
  }

  void sendDone(ieee154_reftime_t *referenceTime, bool ackPendingFlag, error_t error)
  {
    uint8_t numCCA = m_numCCA;
    // transmission complete, we're owning the SPI, Rx logic is disabled
    call CC2420Power.rfOff();
    call CC2420Power.flushRxFifo();
    switch (error)
    {
       case SUCCESS:
         m_state = S_RADIO_OFF;
         break;
       case ENOACK:
         m_state = S_TX_LOADED;
         break;
       default: 
         call Leds.led0On(); // internal error!
         break;
    }
    if (error == SUCCESS){
      call CC2420Tx.unlockChipSpi();
      call TxControl.stop();
      call SpiResource.release();
      m_state = S_RADIO_OFF;
    } else
      m_state = S_TX_LOADED;
    if (numCCA == 0)
      signal RadioTx.transmitDone(m_txframe, referenceTime);
    else if (numCCA == 1)
      signal RadioTx.transmitUnslottedCsmaCaDone(m_txframe, ackPendingFlag, m_csmaParams, error);
    else
      signal RadioTx.transmitSlottedCsmaCaDone(m_txframe, referenceTime, ackPendingFlag, 0, m_csmaParams, error);
  }

/* ----------------------- RxControl ----------------------- */

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
      case S_TX_ACTIVE: txDoneRxControlStopped(); break;
      case S_STOPPING: stopContinue(); break;            
      default: // huh ?
           call Leds.led0On(); break;
    }
  }

/* ----------------------- SPI Bus Arbitration ----------------------- */

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

