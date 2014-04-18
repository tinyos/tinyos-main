/*
 * Copyright (c) 2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * The DisseminationEngineImplP component implements the dissemination
 * logic.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2007-09-14 00:22:18 $
 */

#include <DisseminationEngine.h>

module DisseminationEngineImplP {
  provides interface StdControl;

  uses {
    interface DisseminationCache[uint16_t key];
    interface TrickleTimer[uint16_t key];
    interface StdControl as DisseminatorControl[uint16_t id];

    interface AMSend;
    interface Receive;

    interface AMSend as ProbeAMSend;
    interface Receive as ProbeReceive;

    interface Leds;
  }
}
implementation {

  enum { NUM_DISSEMINATORS = uniqueCount("DisseminationTimerC.TrickleTimer") };

  message_t m_buf;
  bool m_running;
  bool m_bufBusy;

  void sendObject( uint16_t key );

  command error_t StdControl.start() {
    uint8_t i;
    for ( i = 0; i < NUM_DISSEMINATORS; i++ ) {
      call DisseminatorControl.start[ i ]();
    }
    m_running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    uint8_t i;
    for ( i = 0; i < NUM_DISSEMINATORS; i++ ) {
      call DisseminatorControl.stop[ i ]();
    }
    m_running = FALSE;
    return SUCCESS;
  }

  event error_t DisseminationCache.start[ uint16_t key ]() {
    error_t result = call TrickleTimer.start[ key ]();
    call TrickleTimer.reset[ key ]();
    return result;
  }

  event error_t DisseminationCache.stop[ uint16_t key ]() {
    call TrickleTimer.stop[ key ]();
    return SUCCESS;
  }

  event void DisseminationCache.newData[ uint16_t key ]() {
    sendObject( key );
    // Note we reset even if not running. This means that if Drip is
    // off and new data is received, it will reset the timer but not
    // send the object. This means that the timer continues properly,
    // but transmissions are suppressed. This is a better approach than
    // just leaving the timer in its prior state.
    
    call TrickleTimer.reset[ key ]();
  }

  event void TrickleTimer.fired[ uint16_t key ]() {

    sendObject( key );
  }

  void sendObject( uint16_t key ) {
    void* object;
    uint8_t objectSize = 0;
    dissemination_message_t* dMsg;
    
    // If Drip is not running or if the Drip buffer
    // is busy, do not send. This fixes Issue #12 in the
    // Google code tracker. -pal
    if ( !m_running || m_bufBusy ) { return; }

    dMsg = 
      (dissemination_message_t*) call AMSend.getPayload( &m_buf, sizeof(dissemination_message_t) );
    if (dMsg != NULL && !m_bufBusy) {
      m_bufBusy = TRUE;
      
      dMsg->key = key;
      dMsg->seqno = call DisseminationCache.requestSeqno[ key ]();
      
      if ( dMsg->seqno != DISSEMINATION_SEQNO_UNKNOWN ) {
	object = call DisseminationCache.requestData[ key ]( &objectSize );
	if ((objectSize + sizeof(dissemination_message_t)) > 
	    call AMSend.maxPayloadLength()) {
	  objectSize = call AMSend.maxPayloadLength() - sizeof(dissemination_message_t);
	}
	memcpy( dMsg->data, object, objectSize );
      }      
      call AMSend.send( AM_BROADCAST_ADDR,
			&m_buf, sizeof( dissemination_message_t ) + objectSize );
    }
  }

  event void ProbeAMSend.sendDone( message_t* msg, error_t error ) {
    m_bufBusy = FALSE;
  }

  event void AMSend.sendDone( message_t* msg, error_t error ) {
    m_bufBusy = FALSE;
  }

  event message_t* Receive.receive( message_t* msg, 
				    void* payload, 
				    uint8_t len ) {

    dissemination_message_t* dMsg = 
      (dissemination_message_t*) payload;

    uint16_t key = dMsg->key;
    uint32_t incomingSeqno = dMsg->seqno;
    uint32_t currentSeqno = call DisseminationCache.requestSeqno[ key ]();

    if ( !m_running ) { return msg; }

    if ( currentSeqno == DISSEMINATION_SEQNO_UNKNOWN &&
	 incomingSeqno != DISSEMINATION_SEQNO_UNKNOWN ) {

      call DisseminationCache.storeData[ key ]
	( dMsg->data, 
	  len - sizeof( dissemination_message_t ),
	  incomingSeqno );
      
      call TrickleTimer.reset[ key ]();
      return msg;
    }

    if ( incomingSeqno == DISSEMINATION_SEQNO_UNKNOWN &&
	 currentSeqno != DISSEMINATION_SEQNO_UNKNOWN ) {

      call TrickleTimer.reset[ key ]();
      return msg;
    }

    if ( (int32_t)( incomingSeqno - currentSeqno ) > 0 ) {

      call DisseminationCache.storeData[key]
	( dMsg->data, 
	  len - sizeof(dissemination_message_t),
	  incomingSeqno );
      dbg("Dissemination", "Received dissemination value 0x%08x,0x%08x @ %s\n", (int)key, (int)incomingSeqno, sim_time_string());
      call TrickleTimer.reset[ key ]();

    } else if ( (int32_t)( incomingSeqno - currentSeqno ) == 0 ) {
      
      call TrickleTimer.incrementCounter[ key ]();

    } else {

      // Still not sure which of these is the best. Immediate send for now.
      sendObject( key );
      // call TrickleTimer.reset[ key ]();

    }

    return msg;
  }

  event message_t* ProbeReceive.receive( message_t* msg, 
					 void* payload, 
					 uint8_t len) {
    
    dissemination_probe_message_t* dpMsg = 
      (dissemination_probe_message_t*) payload;

    if ( !m_running ) { return msg; }

    if ( call DisseminationCache.requestSeqno[ dpMsg->key ]() != 
	 DISSEMINATION_SEQNO_UNKNOWN ) {    
      sendObject( dpMsg->key );
    }

    return msg;
  }
  
  default command void* 
    DisseminationCache.requestData[uint16_t key]( uint8_t* size ) { return NULL; }

  default command void 
    DisseminationCache.storeData[uint16_t key]( void* data, 
						uint8_t size, 
						uint32_t seqno ) {}

  default command uint32_t 
    DisseminationCache.requestSeqno[uint16_t key]() { return DISSEMINATION_SEQNO_UNKNOWN; }

  default command error_t TrickleTimer.start[uint16_t key]() { return FAIL; }

  default command void TrickleTimer.stop[uint16_t key]() { }

  default command void TrickleTimer.reset[uint16_t key]() { }

  default command void TrickleTimer.incrementCounter[uint16_t key]() { }

  default command error_t DisseminatorControl.start[uint16_t id]() { return FAIL; }
  default command error_t DisseminatorControl.stop[uint16_t id]() { return FAIL; }
}
