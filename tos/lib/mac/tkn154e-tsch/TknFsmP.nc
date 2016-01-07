/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

#include "tkn_fsm.h"

#ifdef TKNFSM_ENABLE_DEBUG_PRINT

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#define TKNFSM_DEBUG(str, fsmname) printf((str), (fsmname))
#define TKNFSM_DEBUG_EVENT(s, e) printf("TknFsm[%s]: Received event 0x%x in state 0x%x\n", fsm_name, (e), (s))
#define TKNFSM_DEBUG_TRANSITION(from, to) printf("TknFsm[%s]: Transition 0x%x -> 0x%x\n", fsm_name, (from), (to))
#else
#define TKNFSM_DEBUG(str, fsmname)
#define TKNFSM_DEBUG_EVENT(s, e)
#define TKNFSM_DEBUG_TRANSITION(from, to)
#endif

/**
 * Implementation of the generic TKN finite state machine
 *
 * This component keeps a single state variable. The state can be arbitrarily
 * changed at any time. Actions are executed once an event is received.
 * An external lookup table is used to decide which event handler to call
 * depending on the current state and event. Event handlers are identified by
 * IDs and the mapping between IDs and handling functions happens externally by
 * wiring to the matching TknFsmStateHandler instance.
 */
generic module TknFsmP(char fsm_name[])
{
  provides {
    interface TknFsm as Fsm;
    interface TknFsmStateHandler as StateHandler[uint8_t shandler];
  }
  uses {
    ;
    interface TknEventReceive as EventReceive;
  }
}
implementation
{
  tknfsm_state_entry_t* event_handler_table;
  uint8_t num_event_handlers;
  tknfsm_state_t current_state;

  inline tknfsm_state_entry_t* getEventHandler(tknfsm_state_t state, tknfsm_event_t e) {
    uint8_t i;
    tknfsm_state_entry_t* entry;
    for (i = 0; i < num_event_handlers; i++) {
      entry = &event_handler_table[i];
      if (entry->state == state || entry->state == TKNFSM_STATE_ANY) {
        if (entry->e == e || entry->e == TKNFSM_EVENT_ANY) {
          return entry;
        }
      }
    }

    // not found
    return NULL;
  }

  command tknfsm_status_t Fsm.setEventHandlerTable(tknfsm_state_entry_t* table, uint8_t num) {
    if (table == NULL) return TKNFSM_STATUS_INVALID_ARGUMENT;
    atomic {
      num_event_handlers = num;
      event_handler_table = table;
    }
    return TKNFSM_STATUS_SUCCESS;
  }

  async event tknfsm_status_t EventReceive.receive(tknfsm_event_t e) {
    tknfsm_state_entry_t* entry;
    tknfsm_state_t s;

    atomic s = current_state;

    TKNFSM_DEBUG_EVENT(s, e);

    // search for a matching entry in the table
    entry = getEventHandler(s, e);
    if (entry == NULL) {
      TKNFSM_DEBUG("TknFsm[%s]: No event handler found! Ignoring event...\n", fsm_name);
      return TKNFSM_STATUS_NO_EVENT_HANDLER;
    }

    // TODO do the state transition
    call Fsm.transitToState(entry->pre_transition);

    // execute the event handler
    signal StateHandler.handle[entry->handler_id]();
    return TKNFSM_STATUS_SUCCESS;
  }

  default async event void StateHandler.handle[uint8_t shandler]() {
#ifdef TKNFSM_ENABLE_DEBUG_PRINT
    tknfsm_state_t s;

    atomic s = current_state;

    TKNFSM_DEBUG_EVENT(s, shandler);
    TKNFSM_DEBUG("TknFsm[%s]: Unwired event handler called!\n", fsm_name);
#endif
  }

  async command void Fsm.forceState(tknfsm_state_t s) {
    // TODO is this function needed?
    TKNFSM_DEBUG("TknFsm[%s]: Forcing state!\n", fsm_name);
    atomic {
      TKNFSM_DEBUG_TRANSITION(current_state, s);
      current_state = s;
    }
  }

  async command void Fsm.transitToState(tknfsm_state_t s) {
    atomic {
      if (s == current_state) {
        TKNFSM_DEBUG("TknFsm[%s]: Transition to same state.\n", fsm_name);
      }
      else {
        TKNFSM_DEBUG_TRANSITION(current_state, s);
        current_state = s;
      }
    }
  }
}
