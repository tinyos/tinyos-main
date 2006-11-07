/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:30:50 $
 */

module CC2420CsmaP {

  provides interface Init;
  provides interface SplitControl;
  provides interface Send;

  uses interface Resource;
  uses interface CC2420Power;
  uses interface AsyncStdControl as SubControl;
  uses interface CC2420Transmit;
  uses interface CsmaBackoff;
  uses interface Random;
  uses interface AMPacket;
  uses interface Leds;

}

implementation {

  enum {
    S_PREINIT,
    S_STOPPED,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
    S_TRANSMIT,
  };

  message_t* m_msg;
  uint8_t m_state = S_PREINIT;
  uint8_t m_dsn;
  error_t sendErr = SUCCESS;
  
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();

  cc2420_header_t* getHeader( message_t* msg ) {
    return (cc2420_header_t*)( msg->data - sizeof( cc2420_header_t ) );
  }

  cc2420_metadata_t* getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

  command error_t Init.init() {
    
    if ( m_state != S_PREINIT )
      return FAIL;

    m_state = S_STOPPED;

    return SUCCESS;

  }

  command error_t SplitControl.start() {

    if ( m_state != S_STOPPED ) 
      return FAIL;

    m_state = S_STARTING;

    m_dsn = call Random.rand16();
    call CC2420Power.startVReg();

    return SUCCESS;

  }

  async event void CC2420Power.startVRegDone() {
    call Resource.request();
  }

  event void Resource.granted() {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() {
    call SubControl.start();
    call CC2420Power.rxOn();
    call Resource.release();
    post startDone_task();
  }

  task void startDone_task() {
    m_state = S_STARTED;
    signal SplitControl.startDone( SUCCESS );
  }

  command error_t SplitControl.stop() {

    if ( m_state != S_STARTED )
      return FAIL;

    m_state = S_STOPPING;

    call SubControl.stop();
    call CC2420Power.stopVReg();
    post stopDone_task();

    return SUCCESS;

  }

  task void stopDone_task() {
    m_state = S_STOPPED;
    signal SplitControl.stopDone( SUCCESS );
  }

  command error_t Send.cancel( message_t* p_msg ) {
    return FAIL;
  }

  command error_t Send.send( message_t* p_msg, uint8_t len ) {
    
    cc2420_header_t* header = getHeader( p_msg );
    cc2420_metadata_t* metadata = getMetadata( p_msg );

    atomic {
      if ( m_state != S_STARTED )
        return FAIL;
      m_state = S_TRANSMIT;
      m_msg = p_msg;
      header->dsn = ++m_dsn;
    }

    header->length = len;
    header->fcf &= 1 << IEEE154_FCF_ACK_REQ;
    header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
		     ( 1 << IEEE154_FCF_INTRAPAN ) |
		     ( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
		     ( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) );
    header->src = call AMPacket.address();
    metadata->ack = FALSE;
    metadata->rssi = 0;
    metadata->lqi = 0;
    metadata->time = 0;

    call CC2420Transmit.sendCCA( m_msg );

    return SUCCESS;

  }

  command void* Send.getPayload(message_t* m) {
    return m->data;
  }

  command uint8_t Send.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  async event uint16_t CsmaBackoff.initial( message_t* m ) {
    return ( call Random.rand16() & 0x1f ) + 1;
  }

  async event uint16_t CsmaBackoff.congestion( message_t* m ) {
    return ( call Random.rand16() & 0x7 ) + 1;
  }

  async event void CC2420Transmit.sendDone( message_t* p_msg, error_t err ) {
    atomic sendErr = err;
    post sendDone_task();
  }

  task void sendDone_task() {
    error_t packetErr;
    atomic packetErr = sendErr;
    m_state = S_STARTED;
    signal Send.sendDone( m_msg, packetErr );
  }

}

