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
#ifndef _TKN_FSM_H_
#define _TKN_FSM_H_

typedef uint8_t tknfsm_status_t;

typedef uint8_t tknfsm_state_t;

typedef uint8_t tknfsm_event_t;

typedef struct {
  tknfsm_state_t state;
  tknfsm_event_t e;
  tknfsm_state_t pre_transition;
  uint8_t handler_id;
} tknfsm_state_entry_t;

enum {
  TKNFSM_STATE_NONE = 0x0,
  TKNFSM_STATE_INIT = 0xF1,
  TKNFSM_STATE_ANY = 0xF2,
  TKNFSM_EVENT_NONE = 0x0,
  TKNFSM_EVENT_INIT = 0xF1,
  TKNFSM_EVENT_ANY = 0xF2
};

enum {
  TKNFSM_STATUS_SUCCESS,
  TKNFSM_STATUS_INVALID_ARGUMENT,
  TKNFSM_STATUS_NO_EVENT_HANDLER
};

#endif /* _TKN_FSM_H_ */
