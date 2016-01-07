/*
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

#define NEW_PRINTF_SEMANTICS
#include "printf.h"

#include "app_config.h"

configuration AppTestTknFsmC
{
}
implementation {
  components MainC, LedsC, TestTknFsmC as App;
  App.Boot -> MainC;
  App.Leds -> LedsC;

  components PrintfC, SerialStartC;

  components new TimerMilliC() as Timer0;
  App.Timer0 -> Timer0;

  components new TknFsmP("AppFsm") as Fsm;
  App.fsm -> Fsm;
  App.fsmReceive <- Fsm;

  components HandlerP;
  HandlerP.Fsm -> Fsm;
  Fsm.StateHandler[HANDLER_INIT] <- HandlerP.Init;
  Fsm.StateHandler[HANDLER_AONE] <- HandlerP.Aone;
  Fsm.StateHandler[HANDLER_ATWO] <- HandlerP.Atwo;
  Fsm.StateHandler[HANDLER_BONE] <- HandlerP.Bone;
  Fsm.StateHandler[HANDLER_BTWO] <- HandlerP.Btwo;
  Fsm.StateHandler[HANDLER_CONE] <- HandlerP.Cone;
  Fsm.StateHandler[HANDLER_CTWO] <- HandlerP.Ctwo;
}
