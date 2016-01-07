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
#ifndef _TEST_TKN_FSM_CONFIG_H_
#define _TEST_TKN_FSM_CONFIG_H_

enum {
  STATE_A = 1, STATE_B = 2, STATE_C = 3,
  EVENT_ONE = 1, EVENT_TWO = 2
};
enum {
  HANDLER_INIT = unique("TestTknFsm.handler"),
  HANDLER_AONE = unique("TestTknFsm.handler"),
  HANDLER_ATWO = unique("TestTknFsm.handler"),
  HANDLER_BONE = unique("TestTknFsm.handler"),
  HANDLER_BTWO = unique("TestTknFsm.handler"),
  HANDLER_CONE = unique("TestTknFsm.handler"),
  HANDLER_CTWO = unique("TestTknFsm.handler"),
} e_app_handler_ids;


#endif /* _TEST_TKN_FSM_CONFIG_H_ */
