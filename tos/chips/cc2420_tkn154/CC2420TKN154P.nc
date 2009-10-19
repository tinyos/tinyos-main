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
 * $Revision: 1.4 $
 * $Date: 2009-10-19 14:16:09 $
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
    interface RadioOff;
    interface RadioRx;
    interface RadioTx;
    interface SlottedCsmaCa;
    interface UnslottedCsmaCa;
    interface EnergyDetection;
    interface Set<bool> as RadioPromiscuousMode;
    interface Timestamp;
    interface GetNow<bool> as CCA;
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
    S_ED,
    S_RADIO_OFF,

    S_RESERVE_RX_SPI,
    S_RX_PENDING,
    S_RECEIVING,
    S_OFF_PENDING,

    S_LOAD_TXFIFO_NO_CSMA,
    S_LOAD_TXFIFO_UNSLOTTED,
    S_LOAD_TXFIFO_SLOTTED,
    S_TX_PENDING,
    S_TX_BACKOFF_UNSLOTTED,
    S_TX_BACKOFF_SLOTTED,
    S_TX_ACTIVE_NO_CSMA,
    S_TX_ACTIVE_UNSLOTTED_CSMA,
    S_TX_ACTIVE_SLOTTED_CSMA,
  } m_state_t;

  norace m_state_t m_state = S_STOPPED;
  norace ieee154_txframe_t *m_txframe;
  norace error_t m_txResult;
  norace bool m_ackFramePending;
  norace uint16_t m_remainingBackoff;
  norace bool m_resume;
  norace ieee154_csma_t *m_csma;
  bool m_pibUpdated;

  /* timing */
  norace ieee154_timestamp_t *m_timestamp;
  norace uint32_t m_dt;
  norace union {
    uint32_t regular;
    ieee154_timestamp_t native;
  } m_t0;


  /* energy detection */
  int8_t m_maxEnergy;
  uint32_t m_edDuration;
  uint32_t m_edStartTime;

  /* task prototypes */
  task void energyDetectionTask();
  task void startDoneTask();
  task void rxControlStopDoneTask();
  task void configSyncTask();

  /* function prototypes */
  uint8_t dBmToPA_LEVEL(int dbm);
  void txDoneRxControlStopped();
  void rxSpiReserved();
  void txSpiReserved();
  void sendDoneSpiReserved();
  void offSpiReserved();
  void offStopRxDone();
  uint16_t getRandomBackoff(uint8_t BE);
  void loadTxFrame(ieee154_txframe_t *frame);
  void checkEnableRxForACK();

  /* ----------------------- StdControl Operations ----------------------- */

  command error_t SplitControl.start()
  {
    atomic {
      if (m_state == S_RADIO_OFF)
        return EALREADY;
      else if (m_state != S_STOPPED)
        return FAIL;
      m_state = S_STARTING;
    }
    call SpiResource.request(); /* continue in startSpiReserved() */
    return SUCCESS;
  }

  void startSpiReserved()
  {
    /* we own the SPI bus */
    call CC2420Power.startVReg();
  }

  async event void CC2420Power.startVRegDone() 
  {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() 
  {
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
    m_state = S_RADIO_OFF;
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop() 
  {
    atomic {
      if (m_state == S_STOPPED)
        return EALREADY;
      else if (m_state != S_RADIO_OFF)
        return FAIL;
      m_state = S_STOPPING;
    }
    call SpiResource.request();
    return SUCCESS;
  }

  void stopSpiReserved()
  {
    /* we own the SPI bus */
    call CC2420Power.rfOff();
    call CC2420Power.flushRxFifo();
    call CC2420Power.stopOscillator(); 
    call CC2420Power.stopVReg();
    call CC2420Tx.unlockChipSpi();
    call SpiResource.release();
    m_state  = S_STOPPED;
    signal SplitControl.stopDone(SUCCESS);
  }

  /* ----------------------- Helpers / PIB Updates ----------------------- */

  /* Returns a random number [0,(2^BE) - 1] (uniform distr.) */
  /* multiplied by backoff period time (in symbols)          */
  uint16_t getRandomBackoff(uint8_t BE)
  {
    uint16_t res = call Random.rand16();
    uint16_t mask = 0xFFFF;
    mask <<= BE;
    mask = ~mask;
    res &= mask;
    return (res * IEEE154_aUnitBackoffPeriod);
  }

  /* input: power in dBm, output: PA_LEVEL setting for CC2420 TXCTRL register */
  uint8_t dBmToPA_LEVEL(int dBm)
  {
    uint8_t result;
    /* the cc2420 has 8 discrete (documented) values */
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
        /* lower 6 bits are twos-complement in dBm (range -32 to +31 dBm) */
        txpower = (*((ieee154_phyTransmitPower_t*) PIBAttributeValue)) & 0x3F;
        if (txpower & 0x20)
          txpower |= 0xC0; /* make it negative, to be interpreted as int8_t */
        call CC2420Config.setTxPower(dBmToPA_LEVEL((int8_t) txpower));
        break;
      case IEEE154_phyCCAMode:
        call CC2420Config.setCCAMode(*((ieee154_phyCCAMode_t*) PIBAttributeValue));
        break;
    }
    if (m_state == S_RECEIVING || m_state == S_RX_PENDING)
      post configSyncTask();
  }

  task void configSyncTask()
  {
    if (call SpiResource.immediateRequest() == SUCCESS) {
      call CC2420Config.sync(); /* put PIB changes into operation */
      call SpiResource.release();
    } else
      post configSyncTask(); // spin (should be short time, until packet is received)
  }

  command void RadioPromiscuousMode.set( bool val )
  {
    call CC2420Config.setPromiscuousMode(val);
  }

  /* ----------------------- Energy Detection ----------------------- */

  command error_t EnergyDetection.start(uint32_t duration)
  {
    atomic {
      if (m_state == S_ED)
        return EALREADY;
      else if (m_state != S_RADIO_OFF)
        return FAIL;
      m_state = S_ED;
    }
    m_edDuration = duration;
    m_maxEnergy = -128 + 45; /* initialization (45 will be substracted below) */
    call SpiResource.request();
    return SUCCESS;
  }

  void edReserved()
  {
    call CC2420Config.sync(); /* put PIB changes into operation (if any) */
    call CC2420Power.rxOn();
    m_edStartTime = call LocalTime.get();
    post energyDetectionTask();
  }

  task void energyDetectionTask()
  {
    int8_t value;
    if (call CC2420Power.rssi(&value) == SUCCESS)
      if (value > m_maxEnergy)
        m_maxEnergy = value;

    if (call TimeCalc.hasExpired(m_edStartTime, m_edDuration)) {
      /* P = RSSI_VAL + RSSI_OFFSET [dBm]  */
      /* RSSI_OFFSET is approximately -45. */
      m_maxEnergy -= 45; 
      call CC2420Power.rfOff();
      call CC2420Power.flushRxFifo();
      call SpiResource.release();
      m_state = S_RADIO_OFF;
      signal EnergyDetection.done(SUCCESS, m_maxEnergy);
    } else
      post energyDetectionTask();
  }

  /* ----------------------- RadioOff ----------------------- */

  async command error_t RadioOff.off()
  {
    error_t result;
    atomic {
      if (m_state == S_RADIO_OFF)
        return EALREADY;
      else if (m_state != S_RECEIVING)
        return FAIL;
      m_state = S_OFF_PENDING;
    }
    result = call RxControl.stop();
    ASSERT(result == SUCCESS);
    return result;
  }
  
  void offStopRxDone()
  {
    if (call SpiResource.immediateRequest() == SUCCESS)
      offSpiReserved();
    else
      call SpiResource.request();  /* will continue in offSpiReserved() */
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

  /* ----------------------- RadioRx ----------------------- */

  async command error_t RadioRx.enableRx(uint32_t t0, uint32_t dt)
  {
    error_t result;
    atomic {
      if (m_state != S_RADIO_OFF)
        return FAIL;
      m_state = S_RESERVE_RX_SPI;
    }
    m_t0.regular = t0;
    m_dt = dt;
    result = call RxControl.start(); 
    ASSERT(result == SUCCESS);
    if (result == SUCCESS)
      if (call SpiResource.immediateRequest() == SUCCESS)
        rxSpiReserved();
      else
        call SpiResource.request();   /* will continue in rxSpiReserved()  */
    return result; 
  }

  void rxSpiReserved()
  {
    m_state = S_RX_PENDING;
    call CC2420Config.sync(); /* put any pending PIB changes into operation      */
    call TxControl.stop();    /* reset Tx logic for timestamping (SFD interrupt) */
    call TxControl.start();   
    atomic {
      if (call TimeCalc.hasExpired(m_t0.regular, m_dt))
        signal ReliableWait.waitRxDone();
      else
        call ReliableWait.waitRx(m_t0.regular, m_dt); /* will signal waitRxDone() just in time */
    }
  }

  async event void ReliableWait.waitRxDone()
  {
    error_t result;
    atomic {
      m_state = S_RECEIVING;
      result = call CC2420Power.rxOn(); 
    }
    ASSERT(result == SUCCESS);
    call CC2420Tx.lockChipSpi();
    call SpiResource.release();
    signal RadioRx.enableRxDone();
  }

  event message_t* CC2420Rx.received(message_t *frame, ieee154_timestamp_t *timestamp) 
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

  /* ----------------------- RadioTx ----------------------- */

  async command error_t RadioTx.transmit( ieee154_txframe_t *frame, const ieee154_timestamp_t *t0, uint32_t dt )
  {
    if( frame == NULL || frame->header == NULL || 
        frame->payload == NULL || frame->metadata == NULL || 
        (frame->headerLen + frame->payloadLen + 2) > IEEE154_aMaxPHYPacketSize )
      return EINVAL;

    atomic {
      if( m_state != S_RADIO_OFF )
        return FAIL;
      m_state = S_LOAD_TXFIFO_NO_CSMA;
    }
    m_txframe = frame;
    if( t0 == NULL )
      m_dt = 0;
    else {
      memcpy( &m_t0.native, t0, sizeof(ieee154_timestamp_t) );
      m_dt = dt;
    }
    loadTxFrame(frame); /* will continue in loadDoneRadioTx() */
    return SUCCESS;
  }

  void loadDoneRadioTx()
  {
    /* frame was loaded into TXFIFO */
    atomic {
      m_state = S_TX_PENDING;
      if (m_dt == 0)
        signal ReliableWait.waitTxDone();
      else
        call ReliableWait.waitTx(&m_t0.native, m_dt); /* will signal waitTxDone() just in time */
    }
  }

  async event void ReliableWait.waitTxDone()
  {
    error_t result;
    ASSERT(m_state == S_TX_PENDING);
    atomic {
      m_state = S_TX_ACTIVE_NO_CSMA;
      result = call CC2420Tx.send(FALSE); /* transmit without CCA, this must succeed */ 
      checkEnableRxForACK();
    }
    ASSERT(result == SUCCESS); 
  }

  inline void txDoneRadioTx(ieee154_txframe_t *frame, ieee154_timestamp_t *timestamp, error_t result)
  {
    /* transmission completed */
    signal RadioTx.transmitDone(frame, timestamp, result);
  }

  /* ----------------------- UnslottedCsmaCa ----------------------- */

  async command error_t UnslottedCsmaCa.transmit(ieee154_txframe_t *frame, ieee154_csma_t *csma)
  {
    if( frame == NULL || frame->header == NULL || 
        frame->payload == NULL || frame->metadata == NULL || 
        (frame->headerLen + frame->payloadLen + 2) > IEEE154_aMaxPHYPacketSize )
      return EINVAL;
    atomic {
      if( m_state != S_RADIO_OFF )
        return FAIL;
      m_state = S_LOAD_TXFIFO_UNSLOTTED;
    }
    m_txframe = frame;
    m_csma = csma;
    loadTxFrame(frame); /* will continue in nextIterationUnslottedCsma()  */
    return SUCCESS;
  }

  void nextIterationUnslottedCsma()
  {
    /* wait for a random time of [0,(2^BE) - 1] backoff slots */
    uint16_t backoff = getRandomBackoff(m_csma->BE); 
    m_state = S_TX_BACKOFF_UNSLOTTED;
    call ReliableWait.waitBackoff(backoff);  /* will continue in waitBackoffDoneUnslottedCsma()  */
  }

  void waitBackoffDoneUnslottedCsma()
  {
    /* backoff finished, try to transmit now */
    int8_t dummy;
    ieee154_txframe_t *frame = NULL;
    ieee154_csma_t *csma = NULL;

    atomic {
      /* The CC2420 needs to be in an Rx mode for STXONCCA strobe */
      /* Note: the receive logic of the CC2420 driver is not yet  */
      /* started, i.e. we cannot (yet) receive any packets        */
      call CC2420Power.rxOn();
      m_state = S_TX_ACTIVE_UNSLOTTED_CSMA;

      /* wait for CC2420 Rx to calibrate + CCA valid time */
      while (call CC2420Power.rssi(&dummy) != SUCCESS)
        ;

      /* transmit with a single CCA done in hardware (STXONCCA strobe) */
      if (call CC2420Tx.send(TRUE) == SUCCESS) {
        /* frame is being sent now, do we need Rx logic ready for an ACK? */
        checkEnableRxForACK();
      } else {
        /* channel is busy */
        call CC2420Power.rfOff();
        /* we might have accidentally caught something during CCA, flush it out */
        call CC2420Power.flushRxFifo(); 
        m_csma->NB += 1;
        if (m_csma->NB > m_csma->macMaxCsmaBackoffs) {
          /* CSMA-CA failure, we're done. The MAC may decide to retransmit. */
          frame = m_txframe;
          csma = m_csma;
          /* continue below */
        } else {
          /* Retry -> next iteration of the unslotted CSMA-CA */
          m_csma->BE += 1;
          if (m_csma->BE > m_csma->macMaxBE)
            m_csma->BE = m_csma->macMaxBE;
          nextIterationUnslottedCsma();
        }
      }
    }
    if (frame != NULL) {
      call CC2420Tx.unlockChipSpi();
      call TxControl.stop();
      call SpiResource.release();
      m_state = S_RADIO_OFF;
      signal UnslottedCsmaCa.transmitDone(frame, csma, FALSE, FAIL);
    }
  }

  inline void txDoneUnslottedCsma(ieee154_txframe_t *frame, ieee154_csma_t *csma, bool ackPendingFlag, error_t result)
  {
    /* transmission completed */
    signal UnslottedCsmaCa.transmitDone(frame, csma, ackPendingFlag, result);
  }

  /* ----------------------- SlottedCsmaCa ----------------------- */

    /* The slotted CSMA-CA requires very exact timing, because transmissions
     * must start on 320 us backoff boundaries. Because it is accessed over SPI
     * the CC2420 is not good at meeting these timing requirements, so consider 
     * the "SlottedCsmaCa"-code below as experimental. */

  async command error_t SlottedCsmaCa.transmit(ieee154_txframe_t *frame, ieee154_csma_t *csma,
      const ieee154_timestamp_t *slot0Time, uint32_t dtMax, bool resume, uint16_t remainingBackoff)
  {
    if( frame == NULL || frame->header == NULL || slot0Time == NULL ||
        frame->payload == NULL || frame->metadata == NULL || 
        (frame->headerLen + frame->payloadLen + 2) > IEEE154_aMaxPHYPacketSize)
      return EINVAL;
    atomic {
      if( m_state != S_RADIO_OFF )
        return FAIL;
      m_state = S_LOAD_TXFIFO_SLOTTED;
    }
    m_txframe = frame;
    m_csma = csma;
    memcpy( &m_t0.native, slot0Time, sizeof(ieee154_timestamp_t) );
    m_dt = dtMax;
    m_resume = resume;
    m_remainingBackoff = remainingBackoff;
    loadTxFrame(frame); /* will continue in nextIterationSlottedCsma()  */
    return SUCCESS;
  }

  void nextIterationSlottedCsma()
  {
    uint32_t dtTxTarget;
    uint16_t backoff;
    ieee154_txframe_t *frame = NULL;
    ieee154_csma_t *csma = NULL;

    atomic {
      if (m_resume) {
        backoff = m_remainingBackoff;
        m_resume = FALSE;
      } else
        backoff = getRandomBackoff(m_csma->BE);
      dtTxTarget = call TimeCalc.timeElapsed(call ReferenceTime.toLocalTime(&m_t0.native), call LocalTime.get());
      dtTxTarget += backoff;
      if (dtTxTarget > m_dt) {
        /* frame doesn't fit into remaining CAP */
        uint32_t overlap = dtTxTarget - m_dt;
        overlap = overlap + (IEEE154_aUnitBackoffPeriod - (overlap % IEEE154_aUnitBackoffPeriod));
        backoff = overlap;
        frame = m_txframe;
        csma = m_csma;
      } else {
        /* backoff now */
        m_state = S_TX_BACKOFF_SLOTTED;
        call ReliableWait.waitBackoff(backoff);  /* will continue in waitBackoffDoneSlottedCsma()  */
      }
    }
    if (frame != NULL) { /* frame didn't fit in the remaining CAP */
      call CC2420Tx.unlockChipSpi();
      call TxControl.stop();
      call SpiResource.release();
      m_state = S_RADIO_OFF;
      signal SlottedCsmaCa.transmitDone(frame, csma, FALSE, backoff, ERETRY);
    }
  }

  void waitBackoffDoneSlottedCsma()
  {
    int8_t dummy;
    bool ccaFailure = FALSE;
    error_t result = FAIL;
    ieee154_txframe_t *frame = NULL;
    ieee154_csma_t *csma = NULL;

    atomic {
      /* The CC2420 needs to be in an Rx mode for STXONCCA strobe */
      /* Note: the receive logic of the CC2420 driver is not yet  */
      /* started, i.e. we cannot (yet) receive any packets        */
      call CC2420Power.rxOn();
      m_state = S_TX_ACTIVE_SLOTTED_CSMA;

      /* wait for CC2420 Rx to calibrate + CCA valid time */
      while (call CC2420Power.rssi(&dummy) != SUCCESS)
        ;

      /* perform CCA on slot boundary (i.e. 8 symbols after backoff bounday);    */
      /* this platform-specific command is supposed to return just in time, so   */
      /* that the frame will be transmitted exactly on the next backoff boundary */
      if (call ReliableWait.ccaOnBackoffBoundary(&m_t0.native)) {
        /* first CCA succeeded */
        if (call CC2420Tx.send(TRUE) == SUCCESS) {
          /* frame is being sent now, do we need Rx logic ready for an ACK? */
          checkEnableRxForACK();
          return;
        } else
          ccaFailure = TRUE; /* second CCA failed */
      } else
        ccaFailure = TRUE; /* first CCA failed */

      /* did not transmit the frame */
      call CC2420Power.rfOff();
      call CC2420Power.flushRxFifo(); /* we might have (accidentally) caught something */
      m_state = S_LOAD_TXFIFO_SLOTTED;
      if (ccaFailure) {
        m_csma->NB += 1;
        if (m_csma->NB > m_csma->macMaxCsmaBackoffs) {
          /* CSMA-CA failure, we're done. The MAC may decide to retransmit. */
          frame = m_txframe;
          csma = m_csma;
          result = FAIL;
        } else {
          /* next iteration of slotted CSMA-CA */
          m_csma->BE += 1;
          if (m_csma->BE > m_csma->macMaxBE)
            m_csma->BE = m_csma->macMaxBE;
          nextIterationSlottedCsma();
        }
      } else {
        /* frame didn't fit into remaining CAP, this can only happen */
        /* if the runtime overhead was too high. this should actually not happen.  */
        /* (in principle the frame should have fitted, because we checked before) */
        frame = m_txframe;
        csma = m_csma;
        result = ERETRY;
      }
    }
    if (frame != NULL) {
      call CC2420Tx.unlockChipSpi();
      call TxControl.stop();
      call SpiResource.release();
      m_state = S_RADIO_OFF;
      signal SlottedCsmaCa.transmitDone(frame, csma, FALSE, 0, result);
    }
  }

  inline void txDoneSlottedCsmaCa(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag, uint16_t remainingBackoff, error_t result)
  {
    /* transmission completed */
    signal SlottedCsmaCa.transmitDone(frame, csma, ackPendingFlag, remainingBackoff, result);
  }

  /* ----------------------- Common Tx Operations ----------------------- */

  void loadTxFrame(ieee154_txframe_t *frame)
  {
    if (call SpiResource.isOwner() || call SpiResource.immediateRequest() == SUCCESS) 
      txSpiReserved();
    else
      call SpiResource.request(); /* will continue in txSpiReserved() */
  }

  void txSpiReserved()
  {
    error_t result;
    call CC2420Config.sync();
    call TxControl.start();
    result = call CC2420Tx.loadTXFIFO(m_txframe);
    ASSERT(result == SUCCESS);
  }

  async event void CC2420Tx.loadTXFIFODone(ieee154_txframe_t *data, error_t error)
  {
    atomic {
      switch (m_state)
      {
        case S_LOAD_TXFIFO_NO_CSMA: loadDoneRadioTx(); break;
        case S_LOAD_TXFIFO_UNSLOTTED: nextIterationUnslottedCsma(); break;
        case S_LOAD_TXFIFO_SLOTTED: nextIterationSlottedCsma(); break;
        default: ASSERT(0); break;
      }
    }
  }

  void checkEnableRxForACK()
  {
    /* A frame is currently being transmitted, check if we  */
    /* need the Rx logic ready for the ACK                  */
    bool ackRequest = (m_txframe->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST) ? TRUE : FALSE;
    error_t result = SUCCESS;

    if (ackRequest) {
      /* release SpiResource and start Rx logic, so the latter  */
      /* can take over after Tx is finished to receive the ACK */
      call SpiResource.release();
      result = call RxControl.start();
    }
    ASSERT(result == SUCCESS);
  }

  async event void CC2420Tx.sendDone(ieee154_txframe_t *frame, 
      ieee154_timestamp_t *timestamp, bool ackPendingFlag, error_t result)
  {
    m_timestamp = timestamp;
    m_ackFramePending = ackPendingFlag;
    m_txResult = result;
    if (!call SpiResource.isOwner()) {
      /* this means an ACK was requested and during the transmission */
      /* we released the Spi to allow the Rx part to take over */
      ASSERT((frame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST));
      result = call RxControl.stop();
      ASSERT(result == SUCCESS); /* will continue in txDoneRxControlStopped() */
    } else
      sendDoneSpiReserved();
  }

  void txDoneRxControlStopped()
  {
    /* get the Spi to switch radio off */
    if (call SpiResource.isOwner() || call SpiResource.immediateRequest() == SUCCESS) 
      sendDoneSpiReserved();
    else
      call SpiResource.request(); /* will continue in sendDoneSpiReserved() */
  }

  void sendDoneSpiReserved()
  {
    /* transmission completed, we're owning the Spi, Rx logic is disabled */
    m_state_t state = m_state;
    ieee154_txframe_t *frame = m_txframe;
    ieee154_csma_t *csma = m_csma;

    call CC2420Power.rfOff();
    call CC2420Power.flushRxFifo();
    call CC2420Tx.unlockChipSpi();
    call TxControl.stop();
    call SpiResource.release();
    m_state = S_RADIO_OFF;

    if (state == S_TX_ACTIVE_NO_CSMA)
      txDoneRadioTx(frame, m_timestamp, m_txResult); 
    else if (state == S_TX_ACTIVE_UNSLOTTED_CSMA)
      txDoneUnslottedCsma(frame, csma, m_ackFramePending, m_txResult);
    else if (state == S_TX_ACTIVE_SLOTTED_CSMA)
      txDoneSlottedCsmaCa(frame, csma, m_ackFramePending, m_remainingBackoff, m_txResult);
    else
      ASSERT(0);
  }

  async event void CC2420Tx.transmissionStarted( ieee154_txframe_t *frame )
  {
    uint8_t frameType = frame->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = frame->headerLen;
    signal Timestamp.transmissionStarted(frameType, frame->handle, frame->payload, token);
  }

  async event void CC2420Tx.transmittedSFD( uint32_t time, ieee154_txframe_t *frame )
  {
    uint8_t frameType = frame->header->mhr[0] & FC1_FRAMETYPE_MASK;
    uint8_t token = frame->headerLen;
    signal Timestamp.transmittedSFD( time, frameType, frame->handle, frame->payload, token );
  }

  async command void Timestamp.modifyMACPayload( uint8_t token, uint8_t offset, uint8_t* buf, uint8_t len )
  {
    if (m_state == S_TX_ACTIVE_NO_CSMA || 
        m_state == S_TX_ACTIVE_SLOTTED_CSMA ||
        m_state == S_LOAD_TXFIFO_UNSLOTTED )
      call CC2420Tx.modify( offset+1+token, buf, len );
  }

  async event void ReliableWait.waitBackoffDone()
  {
    switch (m_state)
    {
      case S_TX_BACKOFF_SLOTTED: waitBackoffDoneSlottedCsma(); break;
      case S_TX_BACKOFF_UNSLOTTED: waitBackoffDoneUnslottedCsma(); break;
      default: ASSERT(0); break;
    }
  }

  /* ----------------------- RxControl ----------------------- */

  async event void RxControl.stopDone(error_t error)
  {
    post rxControlStopDoneTask();
  }

  task void rxControlStopDoneTask()
  {
    switch (m_state)
    {
      case S_OFF_PENDING:              offStopRxDone(); break;
      case S_TX_ACTIVE_NO_CSMA:        /* fall through */
      case S_TX_ACTIVE_UNSLOTTED_CSMA: /* fall through */
      case S_TX_ACTIVE_SLOTTED_CSMA:   txDoneRxControlStopped(); break;
      default:                         ASSERT(0); break;
    }
  }

  /* ----------------------- SPI Bus Arbitration ----------------------- */

  event void SpiResource.granted() 
  {
    switch (m_state)
    {
      case S_STARTING:                 startSpiReserved(); break;
      case S_ED:                       edReserved(); break;
      case S_RESERVE_RX_SPI:           rxSpiReserved(); break;
      case S_LOAD_TXFIFO_NO_CSMA:      /* fall through */
      case S_LOAD_TXFIFO_UNSLOTTED:    /* fall through */
      case S_LOAD_TXFIFO_SLOTTED:      txSpiReserved(); break;
      case S_TX_ACTIVE_NO_CSMA:        /* fall through */
      case S_TX_ACTIVE_UNSLOTTED_CSMA: /* fall through */
      case S_TX_ACTIVE_SLOTTED_CSMA:   sendDoneSpiReserved(); break;
      case S_STOPPING:                 stopSpiReserved(); break;
      case S_OFF_PENDING:              offSpiReserved(); break;
      default:                         ASSERT(0); break;
    }
  }

  async command bool CCA.getNow()
  {
    return call CC2420Tx.cca();
  }

  default event void SplitControl.startDone(error_t error) {}
  default event void SplitControl.stopDone(error_t error) {}
  
  default async event void UnslottedCsmaCa.transmitDone(ieee154_txframe_t *frame, 
      ieee154_csma_t *csma, bool ackPendingFlag, error_t result) {}
  default async event void SlottedCsmaCa.transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result) {}

  default async event void Timestamp.transmissionStarted(uint8_t frameType, uint8_t msduHandle, uint8_t *msdu, uint8_t token) {}
  default async event void Timestamp.transmittedSFD(uint32_t time, uint8_t frameType, uint8_t msduHandle, uint8_t *msdu, uint8_t token) {}
}

