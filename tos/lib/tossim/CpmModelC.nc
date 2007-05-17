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
 * CPM (closest-pattern matching) is a wireless noise simulation model
 * based on statistical extraction from empirical noise data.
 * This model provides far more precise
 * software simulation environment by exploiting time-correlated noise
 * characteristic and shadowing effect as well as path-loss model. For
 * details, please refer to the paper
 *
 * "Improving Wireless Simulation through Noise Modeling." HyungJune
 * Lee and Philip Levis, IPSN 2007. You can find a copy at
 * http://sing.stanford.edu.
 * 
 * @author Hyungjune Lee, Philip Levis
 * @date   Oct 12 2006
 */ 

#include <sim_gain.h>
#include <sim_noise.h>
#include <randomlib.h>

module CpmModelC {
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

  double timeInMs()   {
    sim_time_t ftime = sim_time();
    int hours, minutes, seconds;
    sim_time_t secondBillionths;
    int temp_time;
    double ms_time;

    secondBillionths = (ftime % sim_ticks_per_sec());
    if (sim_ticks_per_sec() > (sim_time_t)1000000000) {
	secondBillionths /= (sim_ticks_per_sec() / (sim_time_t)1000000000);
    }
    else {
      secondBillionths *= ((sim_time_t)1000000000 / sim_ticks_per_sec());
    }
    temp_time = (int)(secondBillionths/10000);
    
    if (temp_time % 10 >= 5) {
	temp_time += (10-(temp_time%10));
    }
    else {
      temp_time -= (temp_time%10);
    }
    ms_time = (float)(temp_time/100.0);

    seconds = (int)(ftime / sim_ticks_per_sec());
    minutes = seconds / 60;
    hours = minutes / 60;
    seconds %= 60;
    minutes %= 60;
	
    ms_time += (hours*3600+minutes*60+seconds)*1000;

    return ms_time;
  }
	
  //Generate a CPM noise reading
  double noise_hash_generation()   {
    double CT = timeInMs(); 
    uint32_t quotient = ((sim_time_t)(CT*10))/10;
    uint8_t remain = (uint8_t)(((sim_time_t)(CT*10))%10);
    double noise_val;
    uint16_t node_id = sim_node();

    dbg("CpmModelC", "IN: noise_hash_generation()\n");
    if (5 <= remain && remain < 10) {
	noise_val = (double)sim_noise_generate(node_id, quotient+1);
      }
    else {
      noise_val = (double)sim_noise_generate(node_id, quotient);
    }
    dbg("CpmModelC", "OUT: noise_hash_generation()\n");

    return noise_val;
  }

  double packetSnr(receive_message_t* msg) {
    double signalStr = msg->power;
    double noise = noise_hash_generation();
    return (signalStr - noise);
  }
  
  void sim_gain_ack_handle(sim_event_t* evt)  {
    if (outgoing != NULL && requestAck && sim_mote_is_on(sim_node())) {
      signal Model.acked(outgoing);
    }
  }

  sim_event_t receiveEvent;
  // This clear threshold comes from the CC2420 data sheet
  double clearThreshold = -72.0;
  bool collision = FALSE;
  message_t* incoming = NULL;
  int incomingSource;

  command void Model.setClearValue(double value) {
    clearThreshold = value;
    dbg("CpmModelC", "Setting clear threshold to %f\n", clearThreshold);
	
  }
  
  command bool Model.clearChannel() {
    dbg("CpmModelC", "Checking clear channel @ %s: %f <= %f \n", sim_time_string(), (double)noise_hash_generation(), clearThreshold);
    return noise_hash_generation() < clearThreshold;
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

  double prr_estimate_from_snr(double SNR) {
    double beta1 = 1.3687;
    double beta2 = 0.9187;
    double SNR_lin = pow(10.0, SNR/10.0);
    double X = fabs(SNR_lin-beta2);
    double PSE = 0.5*erfc(beta1*sqrt(X/2));
    double prr_hat = pow(1-PSE, 23*2);
    dbg("CpmModelC", "SNR is %lf, PRR is %lf\n", SNR, prr_hat);
    if (prr_hat > 1)
      prr_hat = 1;
    else if (prr_hat < 0)
      prr_hat = 0;
	
    return prr_hat;
  }

  bool shouldReceive(double SNR) {
    double prr = prr_estimate_from_snr(SNR);
    double coin = RandomUniform();
    if ( (prr != 0) && (prr != 1) ) {
      if (coin < prr)
	prr = 1.0;
      else
	prr = 0.0;
    }
    return prr;
  }

  bool checkReceive(receive_message_t* msg) {
    double noise = noise_hash_generation();
    receive_message_t* list = outstandingReceptionHead;
    noise = pow(10.0, noise / 10.0);
    while (list != NULL) {
      if (list != msg) {
	noise += pow(10.0, list->power / 10.0);
      }
      list = list->next;
    }
    noise = 10.0 * log(noise) / log(10.0);
    return shouldReceive(msg->power - noise);
  }
  
  double packetNoise(receive_message_t* msg) {
    double noise = noise_hash_generation();
    receive_message_t* list = outstandingReceptionHead;
    noise = pow(10.0, noise / 10.0);
    while (list != NULL) {
      if (list != msg) {
	noise += pow(10.0, list->power / 10.0);
      }
      list = list->next;
    }
    noise = 10.0 * log(noise) / log(10.0);
    return noise;
  }

  double checkPrr(receive_message_t* msg) {
    return prr_estimate_from_snr(msg->power / packetNoise(msg));
  }
  

  void sim_gain_receive_handle(sim_event_t* evt) {
    receive_message_t* mine = (receive_message_t*)evt->data;
    receive_message_t* predecessor = NULL;
    receive_message_t* list = outstandingReceptionHead;

    dbg("CpmModelC", "Handling reception event @ %s.\n", sim_time_string());
    while (list != NULL) {
      if (list->next == mine) {
	predecessor = list;
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
      dbgerror("CpmModelC", "Incoming packet list structure is corrupted: entry is not the head and no entry points to it.\n");
    }
    dbg("CpmModelC,SNRLoss", "Packet from %i to %i\n", (int)mine->source, (int)sim_node());
    if (!checkReceive(mine)) {
      dbg("CpmModelC,SNRLoss", " - lost packet from as SNR was too low.\n");
      mine->lost = 1;
    }
    if (!mine->lost) {
      dbg_clear("CpmModelC,SNRLoss", "  -signaling reception\n");
      signal Model.receive(mine->msg);
      if (mine->ack) {
        dbg_clear("CpmModelC", " acknowledgment requested, ");
      }
      else {
        dbg_clear("CpmModelC", " no acknowledgment requested.\n");
      }
      // If we scheduled an ack, receiving = 0 when it completes
      if (mine->ack && signal Model.shouldAck(mine->msg)) {
        dbg_clear("CpmModelC", " scheduling ack.\n");
	sim_gain_schedule_ack(mine->source, sim_time() + 1); 
      }
      // We're searching for new packets again
      receiving = 0;
    } // If the packet was lost, then we're searching for new packets again
    else {
      receiving = 0;
      dbg_clear("CpmModelC,SNRLoss", "  -packet was lost.\n");
    }
    free(mine);
  }
   
  // Create a record that a node is receiving a packet,
  // enqueue a receive event to figure out what happens.
  void enqueue_receive_event(int source, sim_time_t endTime, message_t* msg, bool receive, double power) {
    sim_event_t* evt;
    receive_message_t* list;
    receive_message_t* rcv = allocate_receive_message();
    double noiseStr = packetNoise(rcv);
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
      dbg("CpmModelC", "Lost packet from %i due to %i being off\n", source, sim_node());
      rcv->lost = 1;
    }
    else if (!shouldReceive(power - noiseStr)) {
      dbg("CpmModelC,SNRLoss", "Lost packet from %i to %i due to SNR being too low (%i)\n", source, sim_node(), (int)(power - noiseStr));
      rcv->lost = 1;
    }
    else if (receiving) {
      dbg("CpmModelC,SNRLoss", "Lost packet from %i due to %i being mid-reception\n", source, sim_node());
      rcv->lost = 1;
    }
    else {
      receiving = 1;
    }

    list = outstandingReceptionHead;
    while (list != NULL) {
      if (!shouldReceive(list->power - rcv->power)) {
	dbg("Gain,SNRLoss", "Going to lose packet from %i with signal %lf as am receiving a packet from %i with signal %lf\n", list->source, list->power, source, rcv->power);
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
    dbg("CpmModelC", "Enqueing reception event for %i at %llu with power %lf.\n", dest, endTime, power);
    sim_set_node(dest);
    enqueue_receive_event(prevNode, endTime, msg, receive, power);
    sim_set_node(prevNode);
  }

  command void Model.putOnAirTo(int dest, message_t* msg, bool ack, sim_time_t endTime, double power) {
    gain_entry_t* neighborEntry = sim_gain_first(sim_node());
    requestAck = ack;
    outgoing = msg;
    dbg("CpmModelC", "Node %i transmitting to %i, finishes at %llu.\n", sim_node(), dest, endTime);

    while (neighborEntry != NULL) {
      int other = neighborEntry->mote;
      sim_gain_put(other, msg, endTime, ack && (other == dest), power + sim_gain_value(sim_node(), other));
      neighborEntry = sim_gain_next(neighborEntry);
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
