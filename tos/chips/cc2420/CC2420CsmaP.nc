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
 * @version $Revision: 1.6 $ $Date: 2007-04-30 17:24:26 $
 */

module CC2420CsmaP {

  provides interface Init;
  provides interface SplitControl;
  provides interface Send;
  provides interface RadioBackoff[am_id_t amId];

  uses interface Resource;
  uses interface CC2420Power;
  uses interface SplitControl as SpiSplitControl;
  uses interface StdControl as SubControl;
  uses interface CC2420Transmit;
  uses interface RadioBackoff as SubBackoff;
  uses interface Random;
  uses interface AMPacket;
  uses interface Leds;
  uses interface CC2420Packet;

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
  
  error_t sendErr = SUCCESS;
  
  /** TRUE if we are to use CCA when sending the current packet */
  norace bool ccaOn;
  
  /****************** Prototypes ****************/
  task void startDone_task();
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();

  /***************** Init Commands ****************/
  command error_t Init.init() {
    if ( m_state != S_PREINIT ) {
      return FAIL;
    }
    m_state = S_STOPPED;
    return SUCCESS;
  }

  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
    if ( m_state != S_STOPPED ) {
      return FAIL;
    }

    m_state = S_STARTING;
    call SpiSplitControl.start();
    // Wait for SpiSplitControl.startDone()
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    if ( m_state != S_STARTED ) {
      return FAIL;
    }

    m_state = S_STOPPING;
    call SpiSplitControl.stop();
    // Wait for SpiSplitControl.stopDone()
    return SUCCESS;
  }

  /***************** SpiSplitControl Events ****************/
  event void SpiSplitControl.startDone(error_t error) {
    call CC2420Power.startVReg();
  }
  
  event void SpiSplitControl.stopDone(error_t error) {
    call SubControl.stop();
    call CC2420Power.stopVReg();
    post stopDone_task();
  }
    
  /***************** Send Commands ****************/
  command error_t Send.cancel( message_t* p_msg ) {
    return call CC2420Transmit.cancel();
  }

  command error_t Send.send( message_t* p_msg, uint8_t len ) {
    
    cc2420_header_t* header = call CC2420Packet.getHeader( p_msg );
    cc2420_metadata_t* metadata = call CC2420Packet.getMetadata( p_msg );

    atomic {
      if ( m_state != S_STARTED ) {
        return FAIL;
      }
      m_state = S_TRANSMIT;
      m_msg = p_msg;
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
    
    ccaOn = TRUE;
    signal RadioBackoff.requestCca[((cc2420_header_t*)(m_msg->data - 
        sizeof(cc2420_header_t)))->type](m_msg);
    call CC2420Transmit.send( m_msg, ccaOn );
    return SUCCESS;

  }

  command void* Send.getPayload(message_t* m) {
    return m->data;
  }

  command uint8_t Send.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  /**************** RadioBackoff Commands ****************/
  /**
   * Must be called within a requestInitialBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setInitialBackoff[am_id_t amId](uint16_t backoffTime) {
    call SubBackoff.setInitialBackoff(backoffTime);
  }
  
  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setCongestionBackoff[am_id_t amId](uint16_t backoffTime) {
    call SubBackoff.setCongestionBackoff(backoffTime);
  }
  
  /**
   * Must be called within a requestLplBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setLplBackoff[am_id_t amId](uint16_t backoffTime) {
    call SubBackoff.setLplBackoff(backoffTime);
  }
    
  /**
   * Enable CCA for the outbound packet.  Must be called within a requestCca
   * event
   * @param ccaOn TRUE to enable CCA, which is the default.
   */
  async command void RadioBackoff.setCca[am_id_t amId](bool useCca) {
    ccaOn = useCca;
  }
  

  /**************** Events ****************/
  async event void CC2420Transmit.sendDone( message_t* p_msg, error_t err ) {
    atomic sendErr = err;
    post sendDone_task();
  }

  async event void CC2420Power.startVRegDone() {
    call Resource.request();
  }
  
  event void Resource.granted() {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() {
    post startDone_task();
  }
  
  /***************** SubBackoff Events ****************/
  async event void SubBackoff.requestInitialBackoff(message_t *msg) {
    call SubBackoff.setInitialBackoff ( call Random.rand16() 
        % (0x1F * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
        
    signal RadioBackoff.requestInitialBackoff[((cc2420_header_t*)(msg->data - 
        sizeof(cc2420_header_t)))->type](msg);
  }

  async event void SubBackoff.requestCongestionBackoff(message_t *msg) {
    call SubBackoff.setCongestionBackoff( call Random.rand16() 
        % (0x7 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);

    signal RadioBackoff.requestCongestionBackoff[((cc2420_header_t*)(msg->data - 
        sizeof(cc2420_header_t)))->type](msg);
  }
  
  async event void SubBackoff.requestLplBackoff(message_t *msg) {
    call SubBackoff.setLplBackoff(call Random.rand16() % 10);
        
    signal RadioBackoff.requestLplBackoff[((cc2420_header_t*)(msg->data - 
        sizeof(cc2420_header_t)))->type](msg);
  }
  
  async event void SubBackoff.requestCca(message_t *msg) {
    // Lower layers than this do not configure the CCA settings
  }
  
  
  /***************** Tasks ****************/
  task void sendDone_task() {
    error_t packetErr;
    atomic packetErr = sendErr;
    m_state = S_STARTED;
    signal Send.sendDone( m_msg, packetErr );
  }

  task void startDone_task() {
    call SubControl.start();
    call CC2420Power.rxOn();
    call Resource.release();
    m_state = S_STARTED;
    signal SplitControl.startDone( SUCCESS );
  }
  
  task void stopDone_task() {
    m_state = S_STOPPED;
    signal SplitControl.stopDone( SUCCESS );
  }
  
  
  /***************** Functions ****************/


  /***************** Defaults ***************/
  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }
  
  
  default async event void RadioBackoff.requestInitialBackoff[am_id_t amId](
      message_t *msg) {
  }

  default async event void RadioBackoff.requestCongestionBackoff[am_id_t amId](
      message_t *msg) {
  }
  
  default async event void RadioBackoff.requestLplBackoff[am_id_t amId](
      message_t *msg) {
  }
  
  default async event void RadioBackoff.requestCca[am_id_t amId](
      message_t *msg) {
  }
}

