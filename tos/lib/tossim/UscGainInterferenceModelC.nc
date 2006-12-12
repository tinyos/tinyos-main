// $Id: UscGainInterferenceModelC.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $
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
 *
 * This interference model is based off experimental data gathered
 * from mica2 nodes by Dongjin Son and Bhaskar Krishnamachari at USC.
 * It simplifies their observations in two ways. First, rather than
 * a smooth curve, this model makes a binary interference assumption
 * when the packets are within 3dBm of each other (their curve is very
 * sharp, so this seems like an OK simplification for now). Second,
 * it uses an additive signal strength model for interference. Their
 * results (as one might expect from colliding sinusoids) show that
 * interference signal strength is more complex than this.
 *
 * @author Philip Levis
 * @date   Jun 1 2006
 */ 

#include <sim_gain.h>

module UscGainInterferenceModelC {
  provides interface GainRadioModel as Model;
}

implementation {

  
  message_t* outgoing; // If I'm sending, this is my outgoing packet
  bool requestAck;
  bool receiving = 0;  // Whether or not I think I'm receiving a packet
  struct receive_message;
  typedef struct receive_message receive_message_t;
  
  struct receive_message {
    int source;
    sim_time_t start;
    sim_time_t end;
    double power;
    bool lost;
    bool ack;
    message_t* msg;
    receive_message_t* next;
  };

  receive_message_t* outstandingReceptionHead = NULL;

  receive_message_t* allocate_receive_message();
  sim_event_t* allocate_receive_event(sim_time_t t, receive_message_t* m);

  /**
   * Heard signal is equal to the signal strength of ambient noise
   * plus the signal strength of all transmissions. The pow() and
   * log() calls transform dBm into energy and back.
   */
  
  double heardSignal() {
    receive_message_t* current = outstandingReceptionHead;
    double localNoise = sim_gain_sample_noise(sim_node());
    double sig = pow(10.0, localNoise / 10.0);
    dbg("Gain", "Computing noise @ %s: %0.2f", sim_time_string(), localNoise);
    while (current != NULL) {
      sig += pow(10.0, current->power / 10.0);
      	dbg_clear("Gain", " ");
      if (current->power >= 0.0) {
	dbg_clear("Gain", "+");
      }
      dbg_clear("Gain", "%0.2f ", current->power);
      current = current->next;
    }
    dbg_clear("Gain", " = %0.2f\n", 10.0 * log(sig) / log(10.0));
    return 10.0 * log(sig) / log(10.0);
  }
  
  void sim_gain_ack_handle(sim_event_t* evt)  {
    if (outgoing != NULL && requestAck && sim_mote_is_on(sim_node())) {
      signal Model.acked(outgoing);
    }
  }

  sim_event_t receiveEvent;
  // This clear threshold comes from the CC2420 data sheet
  double clearThreshold = -95.0;
  bool collision = FALSE;
  message_t* incoming = NULL;
  int incomingSource;

  command void Model.setClearValue(double value) {
    clearThreshold = value;
    dbg("Gain", "Setting clear threshold to %f\n", clearThreshold);
	
  }
  
  command bool Model.clearChannel() {
    double channel = heardSignal();
    dbg("Gain", "Checking clear channel @ %s: %f <= %f \n", sim_time_string(), channel, clearThreshold);
    return channel < clearThreshold;
  }

  void sim_gain_schedule_ack(int source, sim_time_t t) {
    sim_event_t* ackEvent = (sim_event_t*)malloc(sizeof(sim_event_t));
    ackEvent->mote = source;
    ackEvent->force = 1;
    ackEvent->cancelled = 0;
    ackEvent->time = t;
    ackEvent->handle = sim_gain_ack_handle;
    ackEvent->cleanup = sim_queue_cleanup_event;
    sim_queue_insert(ackEvent);
  }

  void sim_gain_receive_handle(sim_event_t* evt) {
    receive_message_t* mine = (receive_message_t*)evt->data;
    receive_message_t* predecessor = NULL;
    receive_message_t* list = outstandingReceptionHead;
    dbg("Gain", "Handling reception event @ %s.\n", sim_time_string());
    while (list != NULL) {
      if (list->next == mine) {
	predecessor = list;
      }
      if (list != mine) {
	if ((list->power - sim_gain_sensitivity()) < heardSignal()) {
	  dbg("Gain", "Lost packet from %i as I concurrently received a packet stronger than %lf\n", list->source, list->power);
	  list->lost = 1;
	}
      }
      list = list->next;
    }
    if (predecessor) {
      predecessor->next = mine->next;
    }
    else if (mine == outstandingReceptionHead) { // must be head
      outstandingReceptionHead = mine->next;
    }
    else {
      dbgerror("Gain", "Incoming packet list structure is corrupted: entry is not the head and no entry points to it.\n");
    }

    if ((mine->power - sim_gain_sensitivity()) < heardSignal()) {
      dbg("Gain", "Lost packet from %i as its power %lf was below sensitivity threshold\n", mine->source, mine->power);
      mine->lost = 1;
    }
    
    if (!mine->lost) {
      dbg_clear("Gain", "  -signaling reception, ");
      signal Model.receive(mine->msg);
      if (mine->ack) {
        dbg_clear("Gain", " acknowledgment requested, ");
      }
      else {
        dbg_clear("Gain", " no acknowledgment requested.\n");
      }
      // If we scheduled an ack, receiving = 0 when it completes
      if (mine->ack && signal Model.shouldAck(mine->msg)) {
        dbg_clear("Gain", " scheduling ack.\n");
	sim_gain_schedule_ack(mine->source, sim_time() + 1); 
      }
      // We're searching for new packets again
      receiving = 0;
    } // If the packet was lost, then we're searching for new packets again
    else {
      receiving = 0;
      dbg_clear("Gain", "  -packet was lost.\n");
    }
    free(mine);
  }
  
  
  // Create a record that a node is receiving a packet,
  // enqueue a receive event to figure out what happens.
  void enqueue_receive_event(int source, sim_time_t endTime, message_t* msg, bool receive, double power) {
    sim_event_t* evt;
    receive_message_t* list;
    receive_message_t* rcv = allocate_receive_message();
    double sigStr = heardSignal();
    rcv->source = source;
    rcv->start = sim_time();
    rcv->end = endTime;
    rcv->power = power;
    rcv->msg = msg;
    rcv->lost = 0;
    rcv->ack = receive;
    
    // If I'm off, I never receive the packet, but I need to keep track of
    // it in case I turn on and someone else starts sending me a weaker
    // packet. So I don't set receiving to 1, but I keep track of
    // the signal strength.
    if (!sim_mote_is_on(sim_node())) { 
      dbg("Gain", "Lost packet from %i due to %i being off\n", source, sim_node());
      rcv->lost = 1;
    }
    else if ((sigStr + sim_gain_sensitivity()) >= power) {
      dbg("Gain", "Lost packet from %i due to power being below reception threshold (%f >= %f)\n", source, sigStr, power);
      rcv->lost = 1;
    }
    else if (receiving) {
      dbg("Gain", "Lost packet from %i due to being in the midst of a reception.\n", source);
      rcv->lost = 1;
    }
    else { // We are on, are not receiving a packet, and the packet is above the noise floor
      receiving = 1;
    }

    list = outstandingReceptionHead;
    while (list != NULL) {
      if ((list->power - sim_gain_sensitivity()) < power) {
	dbg("Gain", "Lost packet from %i as I concurrently received a packet from %i stronger than %lf\n", list->source, source, list->power);
	list->lost = 1;
      }
      list = list->next;
    }
    
    rcv->next = outstandingReceptionHead;
    
    outstandingReceptionHead = rcv;
    evt = allocate_receive_event(endTime, rcv);
    sim_queue_insert(evt);
  }
  
  void sim_gain_put(int dest, message_t* msg, sim_time_t endTime, bool receive, double power) {
    int prevNode = sim_node();
    dbg("Gain", "Enqueing reception event for %i at %llu.\n", dest, endTime);
    sim_set_node(dest);
    enqueue_receive_event(prevNode, endTime, msg, receive, power);
    sim_set_node(prevNode);
  }

  command void Model.putOnAirTo(int dest, message_t* msg, bool ack, sim_time_t endTime, double power) {
    gain_entry_t* link = sim_gain_first(sim_node());
    requestAck = ack;
    outgoing = msg;
    dbg("Gain", "Node %i transmitting to %i, finishes at %llu.\n", sim_node(), dest, endTime);

    while (link != NULL) {
      int other = link->mote;
      sim_gain_put(other, msg, endTime, ack && (other == dest), power + link->gain);
      link = sim_gain_next(link);
    }
  }
    

  
  
 default event void Model.receive(message_t* msg) {}

 sim_event_t* allocate_receive_event(sim_time_t endTime, receive_message_t* msg) {
   sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
   evt->mote = sim_node();
   evt->time = endTime;
   evt->handle = sim_gain_receive_handle;
   evt->cleanup = sim_queue_cleanup_event;
   evt->cancelled = 0;
   evt->force = 1; // Need to keep track of air even when node is off
   evt->data = msg;
   return evt;
 }

 receive_message_t* allocate_receive_message() {
   return (receive_message_t*)malloc(sizeof(receive_message_t));
 }
 
}
