/* 
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /* This component is the default AM filter component: it does not do anything,
  * it uses no RAM and nesC will compile all code away. Its purpose is to allow
  * other components to shadow (overwrite) it to implement their own
  * filter/statistic component.
  */

#include "AM.h"
module ActiveMessageFilterC {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
  }
  uses {
    interface AMSend as SubAMSend[am_id_t id];
    interface Receive as SubReceive[am_id_t id];
    interface Receive as SubSnoop[am_id_t id];
  }
} implementation {

  command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len){ return call SubAMSend.send[id](addr, msg, len);}
  command error_t AMSend.cancel[am_id_t id](message_t* msg){ return call SubAMSend.cancel[id](msg);}
  command uint8_t AMSend.maxPayloadLength[am_id_t id](){ return call SubAMSend.maxPayloadLength[id]();}
  command void* AMSend.getPayload[am_id_t id](message_t* msg){ return call SubAMSend.getPayload[id](msg);}
  event void SubAMSend.sendDone[am_id_t id](message_t* msg, error_t error) { signal AMSend.sendDone[id](msg, error); }
  default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error) { return; }

  command void* Receive.getPayload[am_id_t id](message_t* msg, uint8_t* len){ return call SubReceive.getPayload[id](msg, len);}
  command uint8_t Receive.payloadLength[am_id_t id](message_t* msg){ return call SubReceive.payloadLength[id](msg);}
  event message_t* SubReceive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return signal Receive.receive[id](msg, payload, len); }
  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){ return msg;}
  
  command void* Snoop.getPayload[am_id_t id](message_t* msg, uint8_t* len){ return call SubSnoop.getPayload[id](msg, len);}
  command uint8_t Snoop.payloadLength[am_id_t id](message_t* msg){ return call SubSnoop.payloadLength[id](msg);}
  event message_t* SubSnoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return signal Snoop.receive[id](msg, payload, len);
  }
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){return msg;}
}
