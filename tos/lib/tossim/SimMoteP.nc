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
 * The TOSSIM abstraction of a mote. By putting simulation state into
 * a component, we can scale and reference this state automatically
 * using nesC's rewriting, rather than managing and indexing into
 * arrays manually.
 *
 * @author Phil Levis
 * @date   August 19 2005
 */

// $Id: SimMoteP.nc,v 1.5 2007-10-08 20:10:09 idgay Exp $

module SimMoteP {
  provides interface SimMote;
}

implementation {
  long long int euid;
  long long int startTime;
  bool isOn;
  sim_event_t* bootEvent;
  
  async command long long int SimMote.getEuid() {
    return euid;
  }
  async command void SimMote.setEuid(long long int e) {
    euid = e;
  }
  async command long long int SimMote.getStartTime() {
    return startTime;
  }
  async command bool SimMote.isOn() {
    return isOn;
  }

  async command int SimMote.getVariableInfo(char* name, void** addr, size_t* size) {
    return __nesc_nido_resolve(sim_node(), name, (uintptr_t*)addr, (size_t*)size);
  }

  command void SimMote.turnOn() {
    if (!isOn) {
      if (bootEvent != NULL) {
	bootEvent->cancelled = TRUE;
      }
      __nesc_nido_initialise(sim_node());
      startTime = sim_time();
      dbg("SimMoteP", "Setting start time to %llu\n", startTime);
      isOn = TRUE;
      sim_main_start_mote();
    }
  }

  async command void SimMote.turnOff() {
    isOn = FALSE;
  }

  
  long long int sim_mote_euid(int mote) @C() @spontaneous() {
    long long int result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.getEuid();
    sim_set_node(tmp);
    return result;
  }

  void sim_mote_set_euid(int mote, long long int id)  @C() @spontaneous() {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.setEuid(id);
    sim_set_node(tmp);
  }
  
  long long int sim_mote_start_time(int mote) @C() @spontaneous() {
    long long int result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.getStartTime();
    sim_set_node(tmp);
    return result;
  }

  int sim_mote_get_variable_info(int mote, char* name, void** ptr, size_t* len) @C() @spontaneous() {
    int result;
    int tmpID = sim_node();
    sim_set_node(mote);
    result = call SimMote.getVariableInfo(name, ptr, len);
    dbg("SimMoteP", "Fetched %s of %i to be %p with len %i (result %i)\n", name, mote, *ptr, *len, result);
    sim_set_node(tmpID);
    return result;
  }
  
  void sim_mote_set_start_time(int mote, long long int t) @C() @spontaneous() {
    int tmpID = sim_node();
    sim_set_node(mote);
    startTime = t;
    dbg("SimMoteP", "Setting start time to %llu\n", startTime);
    sim_set_node(tmpID);
    return;
  }
  
  bool sim_mote_is_on(int mote) @C() @spontaneous() {
    bool result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.isOn();
    sim_set_node(tmp);
    return result;
  }
  
  void sim_mote_turn_on(int mote) @C() @spontaneous() {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.turnOn();
    sim_set_node(tmp);
  }
  
  void sim_mote_turn_off(int mote) @C() @spontaneous() {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.turnOff();
    sim_set_node(tmp);
  }

  void sim_mote_boot_handle(sim_event_t* e) {
    char buf[128];
    sim_print_now(buf, 128);
	   
    bootEvent = (sim_event_t*)NULL;
    dbg("SimMoteP", "Turning on mote %i at time %s.\n", (int)sim_node(), buf);
    call SimMote.turnOn();
  }
  
  void sim_mote_enqueue_boot_event(int mote) @C() @spontaneous() {
    int tmp = sim_node();
    sim_set_node(mote);

    if (bootEvent != NULL)  {
      if (bootEvent->time == startTime) {
	// In case we have a cancelled boot event.
	bootEvent->cancelled = FALSE;
	return;
      }
      else {
	bootEvent->cancelled = TRUE;
      }
    }
    
    bootEvent = (sim_event_t*) malloc(sizeof(sim_event_t));
    bootEvent->time = startTime;
    bootEvent->mote = mote;
    bootEvent->force = TRUE;
    bootEvent->data = NULL;
    bootEvent->handle = sim_mote_boot_handle;
    bootEvent->cleanup = sim_queue_cleanup_event;
    sim_queue_insert(bootEvent);
    
    sim_set_node(tmp);
  }

}
