/*
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2007 Johns Hopkins University.
 * All rights reserved.
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#include "DelugeMsgs.h"
#include "BitVecUtils.h"

module DelugePageTransferP
{
  provides interface DelugePageTransfer;
  uses {
    interface BitVecUtils;
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    
    interface Receive as ReceiveDataMsg;
    interface Receive as ReceiveReqMsg;
    interface AMSend as SendDataMsg;
    interface AMSend as SendReqMsg;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as Timer;
    interface Random;
    
    interface Leds;
    //interface StatsCollector;
  }
}

implementation
{
  // send/receive page buffers, and state variables for buffers
  uint8_t pktsToSend[DELUGET2_PKT_BITVEC_SIZE];    // bit vec of packets to send
  uint8_t pktsToReceive[DELUGET2_PKT_BITVEC_SIZE]; // bit vec of packets to receive

  DelugeDataMsg rxQueue[DELUGE_QSIZE];
  uint8_t       head, size;

  enum {
    S_DISABLED,
    S_IDLE,     
    S_TX_LOCKING,
    S_SENDING,
    S_RX_LOCKING,
    S_RECEIVING,
  };
  
  // state variables
  uint8_t      state        = S_DISABLED;
  uint16_t     nodeAddr;
  uint8_t      remainingAttempts;
  bool         suppressReq;
  object_id_t  objToSend    = DELUGE_INVALID_OBJID;
  page_num_t   pageToSend   = DELUGE_INVALID_PGNUM;
  object_id_t  workingObjid = DELUGE_INVALID_OBJID;
  page_num_t   workingPgNum = DELUGE_INVALID_PGNUM;
  uint8_t      imgNum       = 0;
  
  message_t pMsgBuf;
  bool      isBusy_pMsgBuf = FALSE;
  uint8_t   publisher_addr;   // For collecting stats only
  
  void changeState(uint8_t newState);
  
  void startReqTimer(bool first)
  {
    uint32_t delay;
    if (first) {
      delay = DELUGE_MIN_DELAY + (call Random.rand32() % DELUGE_MAX_REQ_DELAY);
    } else {
      delay = DELUGE_NACK_TIMEOUT + (call Random.rand32() % DELUGE_NACK_TIMEOUT);
    }
    call Timer.startOneShot(delay);
  }
  
  void setupReqMsg()
  {
    DelugeReqMsg *pReqMsg = (DelugeReqMsg *)(call SendReqMsg.getPayload(&pMsgBuf, sizeof(DelugeReqMsg)));
    if (pReqMsg == NULL) {
      return;
    }
    if (state == S_RX_LOCKING) {
      if (isBusy_pMsgBuf) {
        return;
      }
      isBusy_pMsgBuf = TRUE;
      changeState(S_RECEIVING);
      pReqMsg->dest = nodeAddr;
      pReqMsg->sourceAddr = TOS_NODE_ID;
      pReqMsg->objid = workingObjid;
      pReqMsg->pgNum = workingPgNum;
    }
    
    if (state != S_RECEIVING) {
      return;
    }
    
    // suppress request
    if (suppressReq) {
      startReqTimer(FALSE);
      suppressReq = FALSE;
    }
    // tried too many times, give up
    else if (remainingAttempts == 0) {
      changeState(S_IDLE);
    }
    // send req message
    else {
      uint32_t i;
      for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
        pReqMsg->requestedPkts[i] = pktsToReceive[i];
      }
      //memcpy(pReqMsg->requestedPkts, pktsToReceive, DELUGE_PKT_BITVEC_SIZE);
      
      if (call SendReqMsg.send(pReqMsg->dest, &pMsgBuf, sizeof(DelugeReqMsg)) != SUCCESS) {
	startReqTimer(FALSE);
      }
    }
  }
  
  storage_addr_t calcOffset(page_num_t pgNum, uint8_t pktNum)
  {
    return (storage_addr_t)pgNum * (storage_addr_t)DELUGET2_BYTES_PER_PAGE
            + (uint16_t)pktNum * (uint16_t)DELUGET2_PKT_PAYLOAD_SIZE;
            //+ DELUGE_METADATA_SIZE;
  }
  
  void setupDataMsg()
  {
    DelugeDataMsg *pDataMsg = (DelugeDataMsg *)(call SendDataMsg.getPayload(&pMsgBuf, sizeof(DelugeDataMsg)));
    uint16_t nextPkt;
    
    if (state != S_SENDING && state != S_TX_LOCKING) {
      return;
    }
    
    signal DelugePageTransfer.suppressMsgs(objToSend);
    
    if (state == S_TX_LOCKING) {
      if (isBusy_pMsgBuf) {
        return;
      }
      isBusy_pMsgBuf = TRUE;
      changeState(S_SENDING);
      pDataMsg->objid = objToSend;
      pDataMsg->pgNum = pageToSend;
      pDataMsg->pktNum = 0;
    }
    
    if (call BitVecUtils.indexOf(&nextPkt, pDataMsg->pktNum, pktsToSend, DELUGET2_PKTS_PER_PAGE) != SUCCESS) {
      // no more packets to send
      //dbg(DBG_USR1, "DELUGE: SEND_DONE\n");
      changeState(S_IDLE);
    } else {
      pDataMsg->pktNum = nextPkt;
      if (call BlockRead.read[imgNum](calcOffset(pageToSend, nextPkt), pDataMsg->data, DELUGET2_PKT_PAYLOAD_SIZE) != SUCCESS) {
        call Timer.startOneShot(DELUGE_FAILED_SEND_DELAY);
      }
    }
  }
  
  void unlockPMsgBuf()
  {
    isBusy_pMsgBuf = FALSE;
    
    switch(state) {
      case S_TX_LOCKING:
        setupDataMsg();
        break;
      case S_RX_LOCKING:
        setupReqMsg();
        break;
    }
  }
  
  void changeState(uint8_t newState)
  {
    if ((newState == S_DISABLED || newState == S_IDLE)
	&& (state == S_SENDING || state == S_RECEIVING)) {
      unlockPMsgBuf();
    }
    
    state = newState;
  }
  
  void suppressMsgs(object_id_t objid, page_num_t pgNum)
  {
    if (state == S_SENDING || state == S_TX_LOCKING) {
      if (objid < objToSend || (objid == objToSend && pgNum < pageToSend)) {
	uint32_t i;
	changeState(S_IDLE);
	for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
          pktsToSend[i] = 0x00;
	}
	//memset(pktsToSend, 0x00, DELUGE_PKT_BITVEC_SIZE);
      }
    } else if (state == S_RECEIVING || state == S_RX_LOCKING) {
      if (objid < workingObjid || (objid == workingObjid && pgNum <= workingPgNum)) {
	// suppress next request since similar request has been overheard
	suppressReq = TRUE;
      }
    }
  }
  
  void writeData()
  {
    if(call BlockWrite.write[imgNum](calcOffset(rxQueue[head].pgNum, rxQueue[head].pktNum),
                            rxQueue[head].data, DELUGET2_PKT_PAYLOAD_SIZE) != SUCCESS) {
      size = 0;
    }
  }
  
  command error_t DelugePageTransfer.stop()
  {
    uint32_t i;
    
    call Timer.stop();
    changeState(S_DISABLED);
    workingObjid = DELUGE_INVALID_OBJID;
    workingPgNum = DELUGE_INVALID_PGNUM;
    
    for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
      pktsToReceive[i] = 0x00;
    }
    for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
      pktsToSend[i] = 0x00;
    }
    //memset(pktsToReceive, 0x00, DELUGE_PKT_BITVEC_SIZE);
    //memset(pktsToSend, 0x00, DELUGE_PKT_BITVEC_SIZE);
    
    return SUCCESS;
  }
  
  command error_t DelugePageTransfer.setWorkingPage(object_id_t new_objid, page_num_t new_pgNum)
  {
    uint32_t i;
    
    if (state == S_DISABLED) {
      changeState(S_IDLE);
    }
    
    workingObjid = new_objid;
    workingPgNum = new_pgNum;
    
    for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
      pktsToReceive[i] = 0xFF;
    }
    //memset(pktsToReceive, (nx_uint8_t)0xff, DELUGE_PKT_BITVEC_SIZE);
    
    return SUCCESS;
  }
  
  command bool DelugePageTransfer.isTransferring()
  {
    return (state != S_IDLE && state != S_DISABLED);
  }
  
  command error_t DelugePageTransfer.dataAvailable(uint16_t sourceAddr)
  {
    if (state == S_IDLE) {
      // currently idle, so request data from source
      changeState(S_RX_LOCKING);
      nodeAddr = sourceAddr;
      remainingAttempts = DELUGE_MAX_NUM_REQ_TRIES;
      suppressReq = FALSE;
      
      // randomize request to prevent collision
      startReqTimer(TRUE);
    }
    
    return SUCCESS;
  }
  
  event void Timer.fired()
  {
    setupReqMsg();
    setupDataMsg();
  }
  
  event void SendReqMsg.sendDone(message_t* msg, error_t error)
  {
    if (state != S_RECEIVING) {
      return;
    }
    
    remainingAttempts--;
    // start timeout timer in case request is not serviced
    startReqTimer(FALSE);
  }
  
  event message_t* ReceiveReqMsg.receive(message_t* msg, void* payload, uint8_t len)
  {
    DelugeReqMsg *rxReqMsg = (DelugeReqMsg*)payload;
    object_id_t objid;
    page_num_t pgNum;
    int i;
    
    //dbg(DBG_USR1, "DELUGE: Received REQ_MSG(dest=%d,vNum=%d,imgNum=%d,pgNum=%d,pkts=%x)\n",
    //    rxReqMsg->dest, rxReqMsg->vNum, rxReqMsg->imgNum, rxReqMsg->pgNum, rxReqMsg->requestedPkts[0]);
    
    if (state == S_DISABLED) {
      return msg;
    }
    
    objid = rxReqMsg->objid;
    pgNum = rxReqMsg->pgNum;
    
    // check if need to suppress req or data msgs
    suppressMsgs(objid, pgNum);
    
    // if not for me, ignore request
    if (rxReqMsg->dest != TOS_NODE_ID
        || objid != workingObjid
	|| pgNum >= workingPgNum) {
      return msg;
    }
    
    if (state == S_IDLE
	|| ((state == S_SENDING || state == S_TX_LOCKING)
           && objid == objToSend
           && pgNum == pageToSend)) {
      // take union of packet bit vectors
      for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
        pktsToSend[i] |= rxReqMsg->requestedPkts[i];
      }
    }
    
    if (state == S_IDLE) {
      // not currently sending, so start sending data
      changeState(S_TX_LOCKING);
      objToSend = objid;
      pageToSend = pgNum;
      nodeAddr = AM_BROADCAST_ADDR;
      setupDataMsg();
    }
    
    return msg;
  }
  
  event void SendDataMsg.sendDone(message_t* msg, error_t error)
  {
    DelugeDataMsg *pDataMsg = (DelugeDataMsg *)(call SendDataMsg.getPayload(&pMsgBuf, sizeof (DelugeDataMsg)));
    if (pDataMsg == NULL) {
      return;
    }
    BITVEC_CLEAR(pktsToSend, pDataMsg->pktNum);
    call Timer.startOneShot(2);
    
// For collecting stats
if (error == SUCCESS) {
  //call StatsCollector.endPubPktTransTime();
}
  }
  
  event message_t* ReceiveDataMsg.receive(message_t* msg, void* payload, uint8_t len)
  {
    DelugeDataMsg* rxDataMsg = (DelugeDataMsg*)payload;
    
    if (state == S_DISABLED) {
      return msg;
    }
    
    //dbg(DBG_USR1, "DELUGE: Received DATA_MSG(vNum=%d,imgNum=%d,pgNum=%d,pktNum=%d)\n",
    //    rxDataMsg->vNum, rxDataMsg->imgNum, rxDataMsg->pgNum, rxDataMsg->pktNum);
    
    // check if need to suppress req or data messages
    suppressMsgs(rxDataMsg->objid, rxDataMsg->pgNum);
    
    if (rxDataMsg->objid == workingObjid
	&& rxDataMsg->pgNum == workingPgNum
	&& BITVEC_GET(pktsToReceive, rxDataMsg->pktNum)
	&& size < DELUGE_QSIZE) {
      // got a packet we need
      
// For collecting stats
if (rxDataMsg->pktNum == 0) {
  //call StatsCollector.startRecvPageTransTime(0);
  dbg("Deluge", "%.3f 115 116 116 117 115 1 %d\n", ((float)((sim_time() * 1000) / sim_ticks_per_sec())) / 1000, CC2420_DEF_CHANNEL);
}
call Leds.led1Toggle();
//call Leds.set(rxDataMsg->pktNum);
      
      //dbg(DBG_USR1, "DELUGE: SAVING(pgNum=%d,pktNum=%d)\n", 
      //    rxDataMsg->pgNum, rxDataMsg->pktNum);
      
      // copy data
      memcpy(&rxQueue[head^size], rxDataMsg, sizeof(DelugeDataMsg));
      if (++size == 1) {
        publisher_addr = call AMPacket.source(msg);   // For collecting stats
	writeData();
      }
    }
    
    return msg;
  }
  
  event void BlockRead.readDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    DelugeDataMsg *pDataMsg = (DelugeDataMsg *)(call SendDataMsg.getPayload(&pMsgBuf, sizeof(DelugeDataMsg)));
    // make sure this event for us
    if (buf != pDataMsg->data) {
      return;
    }
    
    if (state != S_SENDING) {
      return;
    }
    
    if (error != SUCCESS) {
      changeState(S_IDLE);
      return;
    }
    
    if (call SendDataMsg.send(nodeAddr, &pMsgBuf, sizeof(DelugeDataMsg)) != SUCCESS) {
      call Timer.startOneShot(DELUGE_FAILED_SEND_DELAY);
    } else {
// For collecting stats
//call StatsCollector.startPubPktTransTime();
//call Leds.led1Toggle();
    }
  }
  
  event void BlockRead.computeCrcDone[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) { }
  
  event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    uint16_t tmp;
    
    // make sure this event for us
    if (buf != rxQueue[head].data) {
      return;
    }
    
    // failed to write
    if (error != SUCCESS) {
      uint32_t i;
      for (i = 0; i < DELUGET2_PKT_BITVEC_SIZE; i++) {
        pktsToReceive[i] = 0xFF;
      }
      size = 0;
      return;
    }
    
    // mark packet as received
    BITVEC_CLEAR(pktsToReceive, rxQueue[head].pktNum);
    head = (head + 1) % DELUGE_QSIZE;
    size--;
    
    if (call BitVecUtils.indexOf(&tmp, 0, pktsToReceive, DELUGET2_PKTS_PER_PAGE) != SUCCESS) {
// For collecting stats
//call StatsCollector.endRecvPageTransTime(publisher_addr);
dbg("Deluge", "%.3f 115 116 116 117 115 2 %d\n", ((float)((sim_time() * 1000) / sim_ticks_per_sec())) / 1000, publisher_addr);

      signal DelugePageTransfer.receivedPage(workingObjid, workingPgNum);
      changeState(S_IDLE);
      size = 0;
    } else if (size) {
      writeData();
    }
  }
  
  event void BlockWrite.eraseDone[uint8_t img_num](error_t error) {}
  event void BlockWrite.syncDone[uint8_t img_num](error_t error) {}
  
  command void DelugePageTransfer.setImgNum(uint8_t new_img_num)
  {
    imgNum = new_img_num;
  }
  
  default command error_t BlockRead.read[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.write[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default async command void Leds.led1Toggle() {}
}
