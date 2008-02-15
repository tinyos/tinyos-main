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
 * The DisseminatorP module holds and synchronizes a single value of a
 * chosen type.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @param t the type of the object that will be disseminated
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2008-02-15 22:51:30 $
 */

generic module DisseminatorP(typedef t) {
  provides interface StdControl;

  provides interface DisseminationValue<t>;
  provides interface DisseminationUpdate<t>;
  provides interface DisseminationCache;

  uses interface Leds;
}
implementation {
  t valueCache;
  bool m_running;

  // A sequence number is 32 bits. The top 16 bits are an incrementing
  // counter, while the bottom 16 bits are a unique node identifier.
  uint32_t seqno = DISSEMINATION_SEQNO_UNKNOWN;

  task void changedTask() {
    signal DisseminationValue.changed();
  }
  
  command error_t StdControl.start() {
    error_t result = signal DisseminationCache.start();
    if ( result == SUCCESS ) { m_running = TRUE; }
    return result;
  }

  command error_t StdControl.stop() {
    if ( !m_running ) { return EOFF; }
    m_running = FALSE;
    return signal DisseminationCache.stop();
  }

  command const t* DisseminationValue.get() {
    return &valueCache;
  }

  command void DisseminationValue.set( const t* val ) {
    valueCache = *val;
  }

  command void DisseminationUpdate.change( t* newVal ) {
    if ( !m_running ) { return; }
    memcpy( &valueCache, newVal, sizeof(t) );
    /* Increment the counter and append the local node ID. */
    seqno = seqno >> 16;
    seqno++;
    if ( seqno == DISSEMINATION_SEQNO_UNKNOWN ) { seqno++; }
    seqno = seqno << 16;
    seqno += TOS_NODE_ID;
    signal DisseminationCache.newData();
    post changedTask();
  }

  command void* DisseminationCache.requestData( uint8_t* size ) {
    *size = sizeof(t);
    return &valueCache;
  }

  command void DisseminationCache.storeData( void* data, uint8_t size,
					     uint32_t newSeqno ) {
    memcpy( &valueCache, data, size < sizeof(t) ? size : sizeof(t) );
    seqno = newSeqno;
    post changedTask();
  }

  command uint32_t DisseminationCache.requestSeqno() {
    return seqno;
  }

  default event void DisseminationValue.changed() { }
}
