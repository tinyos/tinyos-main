// $Id: TossimPacketModelC.nc,v 1.12 2010-06-29 22:07:51 scipio Exp $
/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * This packet-level radio component implements a basic CSMA
 * algorithm. It derives its constants from sim_csma.c. The algorithm
 * is as follows:
 *
 * Transmit iff you measure a clear channel min_free_samples() in a row.
 * Sample up to max_iterations() times. If you do not detect a free
 * channel in this time, signal sendDone with an error of EBUSY.
 * If max_iterations() is zero, then sample indefinitely.
 *
 * On a send request, use an initial backoff in the range of
 * init_low() to init_high().
 * Subsequent backoffs are in the range
         <pre>(low, high) * exponent_base() ^ iterations</pre>
 *
 * The default exponent_base is 1 (constant backoff).
 *
 *
 * @author Philip Levis
 * @date Dec 16 2005
 *
 */

#include <TossimRadioMsg.h>
#include <sim_csma.h>

module TossimPacketModelC { 
  provides {
    interface Init;
    interface SplitControl as Control;
    interface PacketAcknowledgements;
    interface TossimPacketModel as Packet;
  }
  uses interface GainRadioModel;
}
implementation {
  bool initialized = FALSE;
  bool running = FALSE;
  uint8_t backoffCount;
  uint8_t neededFreeSamples;
  message_t* sending = NULL;
  bool transmitting = FALSE;
  uint8_t sendingLength = 0;
  int destNode;
  sim_event_t sendEvent;
  
  message_t receiveBuffer;
  
  tossim_metadata_t* getMetadata(message_t* msg) {
    return (tossim_metadata_t*)(&msg->metadata);
  }
  
  command error_t Init.init() {
    dbg("TossimPacketModelC", "TossimPacketModelC: Init.init() called\n");
    initialized = TRUE;
    // We need to cancel in case an event is still lying around in the queue from
    // before a reboot. Otherwise, the event will be executed normally (node is on),
    // but its memory has been zeroed out.
    sendEvent.cancelled = 1;
    return SUCCESS;
  }

  task void startDoneTask() {
    running = TRUE;
    signal Control.startDone(SUCCESS);
  }

  task void stopDoneTask() {
    running = FALSE;
    signal Control.stopDone(SUCCESS);
  }
  
  command error_t Control.start() {
    if (!initialized) {
      dbgerror("TossimPacketModelC", "TossimPacketModelC: Control.start() called before initialization!\n");
      return FAIL;
    }
    dbg("TossimPacketModelC", "TossimPacketModelC: Control.start() called.\n");
    post startDoneTask();
    return SUCCESS;
  }
  command error_t Control.stop() {
    if (!initialized) {
      dbgerror("TossimPacketModelC", "TossimPacketModelC: Control.stop() called before initialization!\n");
      return FAIL;
    }
    running = FALSE;
    dbg("TossimPacketModelC", "TossimPacketModelC: Control.stop() called.\n");
    post stopDoneTask();
    return SUCCESS;
  }

  
  
  async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
    tossim_metadata_t* meta = getMetadata(msg);
    meta->ack = TRUE;
    return SUCCESS;
  }

  async command error_t PacketAcknowledgements.noAck(message_t* ack) {
    tossim_metadata_t* meta = getMetadata(ack);
    meta->ack = FALSE;
    return SUCCESS;
  }

  async command error_t PacketAcknowledgements.wasAcked(message_t* ack) {
    tossim_metadata_t* meta = getMetadata(ack);
    return meta->ack;
  }
      
  task void sendDoneTask() {
    message_t* msg = sending;
    tossim_metadata_t* meta = getMetadata(msg);
    meta->ack = 0;
    meta->strength = 0;
    meta->time = 0;
    sending = FALSE;
    signal Packet.sendDone(msg, running? SUCCESS:EOFF);
  }

  command error_t Packet.cancel(message_t* msg) {
    return FAIL;
  }

  void start_csma();

  command error_t Packet.send(int dest, message_t* msg, uint8_t len) {
    if (!initialized) {
      dbgerror("TossimPacketModelC", "TossimPacketModelC: Send.send() called, but not initialized!\n");
      return EOFF;
    }
    if (!running) {
      dbgerror("TossimPacketModelC", "TossimPacketModelC: Send.send() called, but not running!\n");
      return EOFF;

    }
    if (sending != NULL) {
      return EBUSY;
    }
    sendingLength = len; 
    sending = msg;
    destNode = dest;
    backoffCount = 0;
    neededFreeSamples = sim_csma_min_free_samples();
    start_csma();
    return SUCCESS;
  }

  void send_backoff(sim_event_t* evt);
  void send_transmit(sim_event_t* evt);
  void send_transmit_done(sim_event_t* evt);
  
  void start_csma() {
    sim_time_t first_sample;

    // The backoff is in terms of symbols. So take a random number
    // in the range of backoff times, and multiply it by the
    // sim_time per symbol.
    sim_time_t backoff = sim_random();
    backoff %= (sim_csma_init_high() - sim_csma_init_low());
    backoff += sim_csma_init_low();
    backoff *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());
    dbg("TossimPacketModelC", "Starting CMSA with %lli.\n", backoff);
    first_sample = sim_time() + backoff;

    sendEvent.mote = sim_node();
    sendEvent.time = first_sample;
    sendEvent.force = 0;
    sendEvent.cancelled = 0;

    sendEvent.handle = send_backoff;
    sendEvent.cleanup = sim_queue_cleanup_none;
    sim_queue_insert(&sendEvent);
  }


  void send_backoff(sim_event_t* evt) {
    backoffCount++;
    if (call GainRadioModel.clearChannel()) {
      neededFreeSamples--;
    }
    else {
      neededFreeSamples = sim_csma_min_free_samples();
    }
    if (neededFreeSamples == 0) {
      sim_time_t delay;
      delay = sim_csma_rxtx_delay();
      delay *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());
      evt->time += delay;
      transmitting = TRUE;
      call GainRadioModel.setPendingTransmission();
      evt->handle = send_transmit;
      sim_queue_insert(evt);
    }
    else if (sim_csma_max_iterations() == 0 ||
	     backoffCount <= sim_csma_max_iterations()) {
      sim_time_t backoff = sim_random();
      sim_time_t modulo = sim_csma_high() - sim_csma_low();
      modulo *= pow(sim_csma_exponent_base(), backoffCount);
      backoff %= modulo;
									
      backoff += sim_csma_init_low();
      backoff *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());
      evt->time += backoff;
      sim_queue_insert(evt);
    }
    else {
      message_t* rval = sending;
      sending = NULL;
      dbg("TossimPacketModelC", "PACKET: Failed to send packet due to busy channel.\n");
      signal Packet.sendDone(rval, EBUSY);
    }
  }

  int sim_packet_header_length() {
    return sizeof(tossim_header_t);
  }
  
  void send_transmit(sim_event_t* evt) {
    sim_time_t duration;
    tossim_metadata_t* metadata = getMetadata(sending);

    duration = 8 * sendingLength;
    duration /= sim_csma_bits_per_symbol();
    duration += sim_csma_preamble_length();
    
    if (metadata->ack) {
      duration += sim_csma_ack_time();
    }
    duration *= (sim_ticks_per_sec() / sim_csma_symbols_per_sec());

    evt->time += duration;
    evt->handle = send_transmit_done;

    dbg("TossimPacketModelC", "PACKET: Broadcasting packet to everyone.\n");
    call GainRadioModel.putOnAirTo(destNode, sending, metadata->ack, evt->time, 0.0, 0.0);
    metadata->ack = 0;

    evt->time += (sim_csma_rxtx_delay() *  (sim_ticks_per_sec() / sim_csma_symbols_per_sec()));

    dbg("TossimPacketModelC", "PACKET: Send done at %llu.\n", evt->time);
	
    sim_queue_insert(evt);
  }

  void send_transmit_done(sim_event_t* evt) {
    message_t* rval = sending;
    sending = NULL;
    transmitting = FALSE;
    dbg("TossimPacketModelC", "PACKET: Signaling send done at %llu.\n", sim_time());
    signal Packet.sendDone(rval, running? SUCCESS:EOFF);
  }

  event void GainRadioModel.receive(message_t* msg) {
    if (running && !transmitting) {
      signal Packet.receive(msg);
    }
  }

  uint8_t error = 0;
  
  event void GainRadioModel.acked(message_t* msg) {
    if (running) {
      tossim_metadata_t* metadata = getMetadata(sending);
      metadata->ack = 1;
      if (msg != sending) {
	error = 1;
	dbg("TossimPacketModelC", "Requested ack for 0x%x, but outgoing packet is 0x%x.\n", msg, sending);
      }
    }
  }

  event bool GainRadioModel.shouldAck(message_t* msg) {
    if (running && !transmitting) {
      return signal Packet.shouldAck(msg);
    }
    else {
      return FALSE;
    }
  }

  default event void Control.startDone(error_t err) {
    return;
  }
 
  default event void Control.stopDone(error_t err) {
    return;
  }
}

