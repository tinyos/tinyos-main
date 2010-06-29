// $Id: BinaryInterferenceModelC.nc,v 1.5 2010-06-29 22:07:51 scipio Exp $
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
 * A binary interference model with length-independent packet error
 * rates (the old TOSSIM-packet story).
 *
 * @author Philip Levis
 * @date   December 2 2005
 */ 

#include <sim_binary.h>

module BinaryInterferenceModelC {
  provides interface SimpleRadioModel as Model;
}

implementation {

  message_t* outgoing;
  bool requestAck;
  
  void sim_binary_ack_handle(sim_event_t* evt)  {
    if (outgoing != NULL && requestAck) {
      signal Model.acked(outgoing);
    }
  }

  sim_event_t receiveEvent;
  sim_time_t clearTime = 0;
  bool collision = FALSE;
  message_t* incoming = NULL;
  int incomingSource;

  
  command bool Model.clearChannel() {
    dbg("Binary", "Checking clear channel @ %s: %i\n", sim_time_string(), (clearTime < sim_time()));
    return clearTime < sim_time();
  }

  
  void sim_schedule_ack(int source, sim_time_t time) {
    sim_event_t* ackEvent = (sim_event_t*)malloc(sizeof(sim_event_t));
    ackEvent->mote = source;
    ackEvent->force = 0;
    ackEvent->cancelled = 0;
    ackEvent->time = time;
    ackEvent->handle = sim_binary_ack_handle;
    ackEvent->cleanup = sim_queue_cleanup_event;
    sim_queue_insert(ackEvent);
  }
  
  void sim_binary_receive_handle(sim_event_t* evt) {
    // If there was no collision, and we pass the loss
    // rate...
    if (!collision) {
      double loss = sim_binary_loss(incomingSource, sim_node());
      int randVal = sim_random() % 1000000;
      dbg("Binary", "Handling receive event for %i.\n", sim_node());
      loss *= 1000000.0;
      if (randVal < (int)loss) {
	signal Model.receive(incoming);

	loss = sim_binary_loss(sim_node(), incomingSource);
	randVal = sim_random() % 1000000;
	loss *= 1000000.0;
	if (randVal < (int)loss) {
	  sim_schedule_ack(incomingSource, sim_time());
	}
      }
      else {
	dbg("Binary", "Packet lost.\n");
      }
    }
    else {
      dbg("Binary", "Receive event for %i was a collision.\n", sim_node());
    }
    incoming = NULL;
  }

  void enqueue_receive_event(int source, sim_time_t endTime, message_t* msg) {
    if (incoming == NULL) {
      dbg("Binary", "Formatting reception event for %i.\n", sim_node());
      receiveEvent.time = endTime;
      receiveEvent.mote = sim_node();
      receiveEvent.cancelled = 0;
      receiveEvent.force = 0;
      receiveEvent.handle = sim_binary_receive_handle;
      receiveEvent.cleanup = sim_queue_cleanup_none;
      incoming = msg;
      sim_queue_insert(&receiveEvent);
      incoming = msg;
      incomingSource = source;
    }
  }
  
  void sim_binary_put(int dest, message_t* msg, sim_time_t endTime, bool receive) {
    int prevNode = sim_node();
    sim_set_node(dest);
    if (clearTime < sim_time() && receive) {
      dbg("Binary", "Enqueing reception event for %i.\n", dest);
      enqueue_receive_event(prevNode, endTime - 1, msg);
      collision = FALSE;
    }
    else {
      collision = TRUE;
    }
    if (endTime > clearTime) {
      clearTime = endTime;
    }
    sim_set_node(prevNode);
  }


  command void Model.putOnAirToAll(message_t* msg, bool ack, sim_time_t endTime) {
    link_t* link = sim_binary_first(sim_node());
    requestAck = FALSE;
    outgoing = msg;
    dbg("Binary", "Node %i broadcasting, first link is 0x%p.\n", sim_node(), sim_binary_first(sim_node()));
    while (link != NULL) {
      int other = link->mote;
      dbg("Binary", "Node %i transmitting to %i.\n", sim_node(), other);
      sim_binary_put(other, msg, endTime, TRUE);
      link = sim_binary_next(link);
    }
  }

  command void Model.putOnAirTo(int dest, message_t* msg, bool ack, sim_time_t endTime) {
    link_t* link = sim_binary_first(sim_node());
    requestAck = ack;
    outgoing = msg;
    
    while (link != NULL) {
      int other = link->mote;
      sim_binary_put(other, msg, endTime, other == dest);
      dbg("Binary", "Node %i transmitting to %i.\n", sim_node(), dest);
      link = sim_binary_next(link);
    }
  }
    

  
  
 default event void Model.receive(message_t* msg) {}


}
