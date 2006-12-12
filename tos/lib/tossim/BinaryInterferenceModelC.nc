// $Id: BinaryInterferenceModelC.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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
