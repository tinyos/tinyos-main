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
 * $Revision: 1.6 $
 * $Date: 2009-05-07 12:41:36 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module IndirectTxP
{
  provides
  {
    interface Init as Reset;
    interface FrameTx[uint8_t client];
    interface WriteBeaconField as PendingAddrWrite;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Get<ieee154_txframe_t*> as GetIndirectTxFrame; 
    interface Purge;
  }
  uses
  {
    interface FrameTx as CoordCapTx;
    interface FrameRx as DataRequestRx;
    interface MLME_GET;
    interface FrameUtility;
    interface Timer<TSymbolIEEE802154> as IndirectTxTimeout;
    interface TimeCalc;
    interface Leds;
  }
}
implementation
{
  enum {
    SEND_THIS_FRAME = 0x80,
    NUM_MAX_PENDING = 7,
  };

  ieee154_txframe_t *m_txFrameTable[NUM_MAX_PENDING];
  ieee154_txframe_t *m_pendingTxFrame;
  uint8_t m_client;
  uint8_t m_numTableEntries;
  uint8_t m_numShortPending;
  uint8_t m_numExtPending;
  task void tryCoordCapTxTask();
  void tryCoordCapTx();

  command error_t Reset.init()
  {
    uint8_t i;
    // CAP/Queue component is always reset first, i.e. there
    // should be no outstanding frames
    call IndirectTxTimeout.stop();
    for (i=0; i<NUM_MAX_PENDING; i++)
      if (m_txFrameTable[i] != NULL)
        signal FrameTx.transmitDone[m_txFrameTable[i]->client](m_txFrameTable[i], IEEE154_TRANSACTION_OVERFLOW);    
    for (i=0; i<NUM_MAX_PENDING; i++)
      m_txFrameTable[i] = NULL; // empty slot
    m_pendingTxFrame = NULL;
    m_numTableEntries = 0;
    m_numShortPending = 0;
    m_numExtPending = 0;
    return SUCCESS;
  }

  uint32_t getPersistenceTimeSymbols()
  {
    // transform macTransactionPersistenceTime PIB attribute
    // from "unit periods" to symbols (cf. page 166) 
    uint32_t unitPeriod;
    ieee154_macBeaconOrder_t BO = call MLME_GET.macBeaconOrder();

    if (BO <= 14) {
      unitPeriod = IEEE154_aBaseSuperframeDuration;
      unitPeriod *= ((uint16_t) 1) << BO;
    } else
      unitPeriod = IEEE154_aBaseSuperframeDuration;
    return unitPeriod * call MLME_GET.macTransactionPersistenceTime();
  }

  command ieee154_status_t Purge.purge(uint8_t msduHandle)
  {
    return IEEE154_INVALID_HANDLE; // TODO
  }

  command uint8_t PendingAddrWrite.write(uint8_t *pendingAddrField, uint8_t maxlen)
  {
    // write the pending addr field (inside the beacon frame)
    uint8_t i, j, k=0;
    uint8_t *longAdrPtr[NUM_MAX_PENDING];
    nxle_uint16_t *adrPtr;
    ieee154_txframe_t *txFrame;
    uint8_t len = call PendingAddrWrite.getLength();

    if (len > maxlen)
      return 0;
    pendingAddrField[0] = 0;
    adrPtr = (nxle_uint16_t *) &pendingAddrField[1];
    for (i=0; i<NUM_MAX_PENDING; i++) {
      if (!m_txFrameTable[i])
        continue;
      txFrame = m_txFrameTable[i];
      if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT) {
        *adrPtr++ = *((nxle_uint16_t*) &txFrame->header->mhr[MHR_INDEX_ADDRESS + sizeof(ieee154_macPANId_t)]);
      } else if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_EXTENDED)
        longAdrPtr[k++] = &(txFrame->header->mhr[MHR_INDEX_ADDRESS + sizeof(ieee154_macPANId_t)]);
    }
    for (i=0; i<m_numExtPending; i++)
      for (j=0; j<8; j++)
        pendingAddrField[1 + 2*m_numShortPending + i*8 + j] = longAdrPtr[i][j];
    pendingAddrField[0] = m_numShortPending | (m_numExtPending << 4);
    return len;
  }

  command uint8_t PendingAddrWrite.getLength()
  {
    return 1 + m_numShortPending * 2 + m_numExtPending * 8;
  }

  command ieee154_status_t FrameTx.transmit[uint8_t client](ieee154_txframe_t *txFrame)
  {
    // send a frame through indirect transmission
    uint8_t i;
    if (m_numTableEntries >= NUM_MAX_PENDING) {
      dbg_serial("IndirectTxP", "Overflow\n");
      return IEEE154_TRANSACTION_OVERFLOW;
    }
    txFrame->client = client;
    txFrame->metadata->timestamp = call IndirectTxTimeout.getNow();
    for (i=0; i<NUM_MAX_PENDING; i++)
      if (!m_txFrameTable[i]) // there must be an empty slot
        break;
    m_txFrameTable[i] = txFrame;
    m_numTableEntries += 1;
    if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT)
      m_numShortPending++;
    else if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_EXTENDED)
      m_numExtPending++;
    if (!call IndirectTxTimeout.isRunning())
      call IndirectTxTimeout.startOneShot(getPersistenceTimeSymbols());
    dbg_serial("IndirectTxP", "Preparing a transmission.\n");
    signal PendingAddrSpecUpdated.notify(TRUE);
    return IEEE154_SUCCESS;
  }

  event message_t* DataRequestRx.received(message_t* frame)
  {
    uint8_t i, j, srcAddressMode, dstAddressMode, *src;
    uint8_t *mhr = MHR(frame);
    uint8_t destMode = (mhr[1] & FC2_DEST_MODE_MASK);

    // received a data request frame from a device
    // have we got some pending data for it ?
    if (!m_numTableEntries)
      return frame;
    srcAddressMode = (mhr[1] & FC2_SRC_MODE_MASK);
    if (!(srcAddressMode & FC2_SRC_MODE_SHORT))
      return frame;  // no source address
    src = mhr + MHR_INDEX_ADDRESS;
    if (destMode == FC2_DEST_MODE_SHORT)
      src += 4;
    else if (destMode == FC2_DEST_MODE_EXTENDED)
      src += 10;
    if (!((mhr[0] & FC1_PAN_ID_COMPRESSION) && (mhr[1] & FC2_DEST_MODE_SHORT)))
      src += 2;
    for (i=0; i<NUM_MAX_PENDING; i++) {
      if (!m_txFrameTable[i])
        continue;
      else {
        dstAddressMode = (m_txFrameTable[i]->header->mhr[1] & FC2_DEST_MODE_MASK);
        if ((dstAddressMode << 4) != srcAddressMode)
          continue;
        else {
          // we know: dstAddressMode IN [2,3]
          uint8_t *dst = &(m_txFrameTable[i]->header->mhr[MHR_INDEX_ADDRESS]) + 2;
          uint8_t len = ((srcAddressMode == FC2_SRC_MODE_SHORT) ? 2 : 8);
          for (j=0; j<len; j++)
            if (*dst != *src)
              break;
          if (j==len)
            break; // match! break from outer loop
        }
      }
    }
    dbg_serial("IndirectTxP", "Received a request, i=%lu, MAX=%lu\n",
        (uint32_t) i,(uint32_t) NUM_MAX_PENDING);
    if (i != NUM_MAX_PENDING) {
      // found a matching frame, mark it for transmission
      m_txFrameTable[i]->client |= SEND_THIS_FRAME;
      post tryCoordCapTxTask();
    } else {
      // TODO: send an empty data frame to the device
    }
    return frame;
  }

  void tryCoordCapTx()
  {
    // iterate over the queued frames and transmit them in the CAP 
    // (if they are marked for transmission)
    uint8_t i;
    if (m_pendingTxFrame == NULL && m_numTableEntries) {
      for (i=0; i<NUM_MAX_PENDING; i++)
        if (m_txFrameTable[i] && (m_txFrameTable[i]->client & SEND_THIS_FRAME)) {
          // TODO: set frame pending bit, if there's more data for this destination
          m_pendingTxFrame = m_txFrameTable[i];
          m_client = m_txFrameTable[i]->client;
          if (call CoordCapTx.transmit(m_txFrameTable[i]) == IEEE154_SUCCESS) {
            dbg_serial("IndirectTxP", "Started a transmission.\n");
          } else {
            m_pendingTxFrame = NULL;
            post tryCoordCapTxTask();
          }
          return; // done - wait for txDone
        }
    }
  }

  task void tryCoordCapTxTask()
  {
    tryCoordCapTx();
  }

  event void IndirectTxTimeout.fired()
  {
    // a transaction has expired 
    uint32_t now = call IndirectTxTimeout.getNow(), dt=0;
    uint32_t persistenceTime = getPersistenceTimeSymbols();
    uint8_t i;

    for (i=0; i<NUM_MAX_PENDING; i++)
      if (m_txFrameTable[i] && m_txFrameTable[i] != m_pendingTxFrame) {
        if (call TimeCalc.hasExpired(m_txFrameTable[i]->metadata->timestamp, persistenceTime)) { 
          ieee154_txframe_t *txFrame = m_txFrameTable[i];
          txFrame->client &= ~SEND_THIS_FRAME;
          m_txFrameTable[i] = NULL;
          m_numTableEntries -= 1;
          if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT)
            m_numShortPending--;
          else if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_EXTENDED)
            m_numExtPending--;
          signal FrameTx.transmitDone[txFrame->client](txFrame, IEEE154_TRANSACTION_EXPIRED);
          signal PendingAddrSpecUpdated.notify(TRUE);
        } else if (call TimeCalc.timeElapsed(m_txFrameTable[i]->metadata->timestamp, now) > dt) {
          dt = call TimeCalc.timeElapsed(m_txFrameTable[i]->metadata->timestamp, now);
        }
      }
    if (dt != 0) {
      if (dt > persistenceTime)
        dt = persistenceTime;
      call IndirectTxTimeout.startOneShot(persistenceTime - dt);
    }
  }

  event void CoordCapTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    uint8_t i;
    // TODO: if CSMA-CA algorithm failed, then frame shall still remain in transaction queue
    dbg_serial("IndirectTxP", "transmitDone(), status: %lu\n", (uint32_t) status);
    for (i=0; i<NUM_MAX_PENDING; i++)
      if (m_txFrameTable[i] == txFrame) {
        m_txFrameTable[i] = NULL; // slot is now empty
        break;
      }
    signal PendingAddrSpecUpdated.notify(TRUE);
    m_pendingTxFrame = NULL;
    txFrame->client = m_client;
    txFrame->client &= ~SEND_THIS_FRAME;
    m_numTableEntries -= 1;
    if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT)
      m_numShortPending--;
    else if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_EXTENDED)
      m_numExtPending--;    
    signal FrameTx.transmitDone[txFrame->client](txFrame, status);
    post tryCoordCapTxTask();
  }

  command ieee154_txframe_t* GetIndirectTxFrame.get() { return m_pendingTxFrame;}
  command error_t PendingAddrSpecUpdated.enable() {return FAIL;}
  command error_t PendingAddrSpecUpdated.disable() {return FAIL;}
  default event void PendingAddrSpecUpdated.notify( bool val ) {return;}
  default event void FrameTx.transmitDone[uint8_t client](ieee154_txframe_t *txFrame, ieee154_status_t status) {}
}
