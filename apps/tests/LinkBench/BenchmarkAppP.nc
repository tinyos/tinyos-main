/*
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
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

module BenchmarkAppP @safe() {

  uses {
    interface Boot;
      
    interface Receive as RxCtrl;
    interface Receive as RxSetup;
    
    interface AMSend  as TxSync;
    interface AMSend  as TxData;
    
    interface SplitControl as Control;
    interface BenchmarkCore;
    interface StdControl as CoreControl;
    interface Init as CoreInit;
    
    interface Packet;
    interface Leds;
  }

}

implementation {

  bool core_configured, core_finished;
  uint8_t resp_request, resp_idx;
  message_t bpkt;
    
  event void Boot.booted() {
    call Control.start();
  }

  event void Control.startDone(error_t error) {
    if (error != SUCCESS)
      call Control.start();
    else {
      call CoreInit.init();
      core_configured = core_finished = FALSE;
    }
  }

  event void Control.stopDone(error_t error) {
    call Control.start();
  }

  task void sendData() {
    datamsg_t* msg = (datamsg_t*)(call Packet.getPayload(&bpkt,sizeof(datamsg_t)));
    call Packet.clear(&bpkt);
    if ( resp_request == CTRL_STAT_REQ && core_finished ) {

      msg->type = DATA_STAT_OK;
      msg->data_idx = resp_idx;
      msg->payload.stat = *(call BenchmarkCore.getStat(resp_idx));
      call TxData.send(AM_BROADCAST_ADDR, &bpkt, sizeof(datamsg_t));
    
    // RESPONSE profile information  
    } else if ( resp_request == CTRL_PROFILE_REQ && core_finished ) {

      msg->type = DATA_PROFILE_OK;
      msg->data_idx = resp_idx;
      msg->payload.profile = *(call BenchmarkCore.getProfile());
      call TxData.send(AM_BROADCAST_ADDR, &bpkt, sizeof(datamsg_t));
    }
      
  }

  task void sendSync() {
    syncmsg_t* msg = (syncmsg_t*)(call Packet.getPayload(&bpkt,sizeof(syncmsg_t)));
    call Packet.clear(&bpkt);
    // RESPONSE the setup acknowledgement if applicable
    if ( resp_request == CTRL_SETUP_SYN && core_configured ) {
      
      msg->type = SYNC_SETUP_ACK;
      msg->edgecnt = call BenchmarkCore.getEdgeCount();
      msg->maxmoteid = call BenchmarkCore.getMaxMoteId();
      dbg("Benchmark","sendSync sending... %d\n",TOS_NODE_ID);      
      call TxSync.send(AM_BROADCAST_ADDR, &bpkt, sizeof(syncmsg_t));
    }
  }

  event void TxSync.sendDone(message_t* bufPtr, error_t error) { }
  event void TxData.sendDone(message_t* bufPtr, error_t error) { }

  event message_t* RxSetup.receive(message_t* bufPtr, void* payload, uint8_t len) {
    setupmsg_t*  msg   = (setupmsg_t*)payload;
    dbg("Benchmark","RxSetup.receive SETUP%d\n",TOS_NODE_ID);
    call BenchmarkCore.setup(msg->config);
    return bufPtr;
  }

  event message_t* RxCtrl.receive(message_t* bufPtr, void* payload, uint8_t len) {
    ctrlmsg_t*  msg   = (ctrlmsg_t*)payload;    
    switch ( msg->type ) {
    
      case CTRL_RESET :
          dbg("Benchmark","RxCtrl.receive RESET %d\n",TOS_NODE_ID);
          call BenchmarkCore.reset();
          call Control.stop();
          break;
          
      case CTRL_SETUP_SYN :
          dbg("Benchmark","RxCtrl.receive SETUP_SYN %d\n",TOS_NODE_ID);
          if( core_configured ) {
            resp_request = msg->type;
            post sendSync();
          }
          break;
          
      case CTRL_START :
          dbg("Benchmark","RxCtrl.receive START %d\n",TOS_NODE_ID);
          if( core_configured ) {
            dbg("Benchmark"," ---- START CORE%d\n",TOS_NODE_ID);
            call CoreControl.start();
          }
          break;
          
      case CTRL_STAT_REQ:
          dbg("Benchmark","RxCtrl.receive STAT_REQ %d\n",TOS_NODE_ID);
          if ( core_finished ) {
            dbg("Benchmark","------- CORE FINISHED\n");
            resp_request = msg->type;
            resp_idx = msg->data_req_idx;
            post sendData();
          } else
            dbg("Benchmark","------- CORE NOT FINISHED\n");
          break;
      case CTRL_PROFILE_REQ:
          dbg("Benchmark","RxCtrl.receive PROFILE_REQ %d\n",TOS_NODE_ID);
          if ( core_finished ) {
            resp_request = msg->type;
            resp_idx = msg->data_req_idx;
            post sendData();
          }
          break;
      default:
          break;
    }
    return bufPtr;
  }
 
  event void BenchmarkCore.finished() {
    core_finished = TRUE;
  }
  
  event void BenchmarkCore.setupDone() {
    core_configured = TRUE;
  }
  
  event void BenchmarkCore.resetDone() {
    core_configured = core_finished = FALSE;
  }
}
