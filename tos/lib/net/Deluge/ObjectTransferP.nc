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

#include "DelugePageTransfer.h"
#include "DelugeMsgs.h"

module ObjectTransferP
{
  provides interface ObjectTransfer;
  uses {
    interface Random;
    interface Timer<TMilli> as Timer;
    interface DelugePageTransfer;
    interface Crc;
    
    interface AMSend as SendAdvMsg;
    interface Receive as ReceiveAdvMsg;
    
    interface BlockWrite[uint8_t img_num];
    
    interface Leds;
//  interface StatsCollector;
  }
}

implementation
{
  // States
  enum {
    S_ERASE,
    S_SYNC,
    S_INITIALIZING_PUB,
    S_INITIALIZING_RECV,
    S_STARTED,
    S_STOPPED,
  };
  
  DelugeAdvTimer advTimers;
  //DelugeNodeDesc nodeDesc;
  uint8_t state = S_STOPPED;
  
  object_id_t cont_receive_new_objid;
  object_size_t cont_receive_new_size;
  uint8_t cont_receive_img_num;
  
  message_t pMsgBuf;
  bool isBusy_pMsgBuf = FALSE;
  DelugeObjDesc curObjDesc;
  
  void updateTimers()
  {
    //advTimers.timer = 0;
  }
  
  void setupAdvTimer()
  {
    advTimers.timer = (uint32_t)0x1 << (advTimers.periodLog2 - 1);
    advTimers.timer += call Random.rand16() & (advTimers.timer - 1);
    advTimers.overheard = 0;
    
    call Timer.stop();
    call Timer.startOneShot(advTimers.timer);
  }
  
  void resetTimer()
  {
    if (advTimers.periodLog2 != DELUGE_MIN_ADV_PERIOD_LOG2) {
      advTimers.periodLog2 = DELUGE_MIN_ADV_PERIOD_LOG2;
      setupAdvTimer();
    }
  }
  
  task void signalObjRecvDone()
  {
    signal ObjectTransfer.receiveDone(SUCCESS);
  }
  
  void setNextPage()
  {
    if (curObjDesc.numPgsComplete < curObjDesc.numPgs) {
      call DelugePageTransfer.setWorkingPage(curObjDesc.objid, curObjDesc.numPgsComplete);
      advTimers.newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;    
      advTimers.overheard = 0;
      resetTimer();
    } else {
      call DelugePageTransfer.setWorkingPage(DELUGE_INVALID_OBJID, DELUGE_INVALID_PGNUM);
      call ObjectTransfer.stop();
      state = S_SYNC;
      call BlockWrite.sync[cont_receive_img_num]();
    }
  }
  
//  bool isNodeDescValid(DelugeNodeDesc* tmpNodeDesc)
//  {
//    return (tmpNodeDesc->crc == crc16(tmpNodeDesc, 4 + sizeof(object_id_t) + 1));
//  }
  
  bool isObjDescValid(DelugeObjDesc* tmpObjDesc)
  {
    return (tmpObjDesc->crc == call Crc.crc16(tmpObjDesc, sizeof(object_id_t) + sizeof(page_num_t))
	    && tmpObjDesc->crc != 0);
  }
  
  void sendAdvMsg(uint16_t addr)
  {
    DelugeAdvMsg *pMsg = (DelugeAdvMsg *)(call SendAdvMsg.getPayload(&pMsgBuf));
    
    if (isBusy_pMsgBuf == FALSE) {
      pMsg->sourceAddr = TOS_NODE_ID;
      pMsg->version = DELUGE_VERSION;
      //pMsg->type = (imagesLoaded) ? DELUGE_ADV_NORMAL : DELUGE_ADV_ERROR;
      pMsg->type = DELUGE_ADV_NORMAL;
      
      // make sure node desc is valid
//      if (!isNodeDescValid(&nodeDesc)) {
//        memset(&nodeDesc, 0xff, sizeof(nodeDesc));
//      }
//      memcpy(&pMsg->nodeDesc, &nodeDesc, sizeof(DelugeNodeDesc));
      
      // make sure obj desc is valid
//      if (!isObjDescValid(&curObjDesc)) {
//        //curObjDesc.objid = objid;
//      }
      memcpy(&(pMsg->objDesc), &curObjDesc, sizeof(DelugeObjDesc));
      
      if (call SendAdvMsg.send(addr, &pMsgBuf, sizeof(DelugeAdvMsg)) == SUCCESS) {
        //dbg(DBG_USR1, "DELUGE: Sent ADV_MSG(imgNum=%d)\n", imgDesc->imgNum);
//call StatsCollector.msg_bcastReq();
        isBusy_pMsgBuf = TRUE;
      }
    }
  }
  
  /**
   * Starts publisher
   */
  command error_t ObjectTransfer.publish(object_id_t new_objid, object_size_t new_size, uint8_t img_num)
  {
    call ObjectTransfer.stop();
//call StatsCollector.startStatsCollector();
    
    state = S_INITIALIZING_PUB;
    curObjDesc.objid = new_objid;
    curObjDesc.numPgs = ((new_size - 1) / DELUGE_BYTES_PER_PAGE) + 1;   // Number of pages to transmit
    curObjDesc.numPgsComplete = curObjDesc.numPgs;   // Publisher doesn't really care about this
    curObjDesc.crc = call Crc.crc16(&curObjDesc, sizeof(object_id_t) + sizeof(page_num_t));
    
    if (state == S_INITIALIZING_PUB) {
      resetTimer();
    }
    state = S_STARTED;
    
    call DelugePageTransfer.setImgNum(img_num);
    call DelugePageTransfer.setWorkingPage(curObjDesc.objid, curObjDesc.numPgs);
    
    return SUCCESS;
  }
  
  /**
   * Resumes the process of preparing the receiver after the target volume is erased
   */
  void cont_receive() {
    state = S_INITIALIZING_RECV;
    curObjDesc.objid = cont_receive_new_objid;
    curObjDesc.numPgs = ((cont_receive_new_size - 1) / DELUGE_BYTES_PER_PAGE) + 1;   // Number of pages to receive
    curObjDesc.numPgsComplete = 0;
    curObjDesc.crc = call Crc.crc16(&curObjDesc, sizeof(object_id_t) + sizeof(page_num_t));
    
    if (state == S_INITIALIZING_RECV) {
      resetTimer();
    }
    state = S_STARTED;
    
    call DelugePageTransfer.setImgNum(cont_receive_img_num);
    setNextPage();
  }
  
  /**
   * Starts receiver
   */
  command error_t ObjectTransfer.receive(object_id_t new_objid, object_size_t new_size, uint8_t img_num)
  {
    error_t error;
    
    call ObjectTransfer.stop();
//call StatsCollector.startStatsCollector();
    
    cont_receive_new_objid = new_objid;
    cont_receive_new_size = new_size;
    cont_receive_img_num = img_num;
    
    error = call BlockWrite.erase[cont_receive_img_num]();
    if (error == SUCCESS) {
      state = S_ERASE;
    }
    
    return error;
  }
  
  command error_t ObjectTransfer.stop()
  {
    call Timer.stop();
    call DelugePageTransfer.stop();
    state = S_STOPPED;
//call StatsCollector.stopStatsCollector();
    
    curObjDesc.objid = DELUGE_INVALID_OBJID;
    curObjDesc.numPgs = DELUGE_INVALID_PGNUM;
    curObjDesc.numPgsComplete = DELUGE_INVALID_PGNUM;
    advTimers.periodLog2 = 0;
    
    return SUCCESS;
  }
  
  event void DelugePageTransfer.receivedPage(object_id_t new_objid, page_num_t new_pgNum)
  {
    if (new_objid == curObjDesc.objid && new_pgNum == curObjDesc.numPgsComplete) {
      curObjDesc.numPgsComplete++;
      curObjDesc.crc = call Crc.crc16(&curObjDesc, sizeof(object_id_t) + sizeof(page_num_t));
      if (curObjDesc.numPgsComplete < curObjDesc.numPgs) {
        setNextPage();
      } else {
        call DelugePageTransfer.setWorkingPage(curObjDesc.objid, curObjDesc.numPgsComplete);
        call ObjectTransfer.stop();
        state = S_SYNC;
        if (call BlockWrite.sync[cont_receive_img_num]() != SUCCESS) {
          post signalObjRecvDone();
        }
      }
    }
  }
  
  event void BlockWrite.syncDone[uint8_t img_num](error_t error)
  {
    if (state == S_SYNC) {
      post signalObjRecvDone();
    }
  }
  
  event void DelugePageTransfer.suppressMsgs(object_id_t new_objid)
  {
    if (new_objid == curObjDesc.objid) {
      advTimers.overheard = 1;
    }
  }
  
  event void SendAdvMsg.sendDone(message_t* msg, error_t error)
  {
    isBusy_pMsgBuf = FALSE;
  }
  
  event message_t* ReceiveAdvMsg.receive(message_t* msg, void* payload, uint8_t len)
  {
    DelugeAdvMsg *rxAdvMsg = (DelugeAdvMsg*)payload;
    DelugeObjDesc *cmpObjDesc = &(rxAdvMsg->objDesc);
    bool isEqual = FALSE;
 
    if (cmpObjDesc->objid != curObjDesc.objid) {
      return msg;
    }
    
    if (rxAdvMsg->version != DELUGE_VERSION 
        //|| !isNodeDescValid(&rxAdvMsg->nodeDesc)
        || state != S_STARTED) {
      return msg;
    }
    
    if (isObjDescValid(&(rxAdvMsg->objDesc)) && state == S_STARTED) {
      // Their image is larger (They have something we need)
      if (cmpObjDesc->numPgsComplete > curObjDesc.numPgsComplete) {
        if ( advTimers.newAdvs == 0 ) {
          call DelugePageTransfer.dataAvailable(rxAdvMsg->sourceAddr);
        }
      }
      // Their image is smaller (They need something we have)
      else if (cmpObjDesc->numPgsComplete < curObjDesc.numPgsComplete) {
        advTimers.newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;
      }      
      // image is the same
      else {
        advTimers.overheard = 1;
        isEqual = TRUE;
      }
      
      if (!isEqual) {
        resetTimer();
      }
    }
    
    return msg;
  }
    
  event void Timer.fired()
  {    
    updateTimers();
    
    if (advTimers.overheard == 0) {
      sendAdvMsg(AM_BROADCAST_ADDR);
    }
    
    if (call DelugePageTransfer.isTransferring())
      advTimers.newAdvs = DELUGE_NUM_NEWDATA_ADVS_REQUIRED;
    else if (advTimers.newAdvs > 0)
      advTimers.newAdvs--;
    
    if (advTimers.newAdvs == 0 &&
        advTimers.periodLog2 < DELUGE_MAX_ADV_PERIOD_LOG2) {
      advTimers.periodLog2++;
    }
    
    setupAdvTimer();
  }
  
  default command error_t BlockWrite.erase[uint8_t img_num]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t img_num]() { return FAIL; }
  
  event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  event void BlockWrite.eraseDone[uint8_t img_num](error_t error)
  {
    if (state == S_ERASE) {
      cont_receive();
    }
  }
}
