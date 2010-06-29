/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#ifndef TOSTHREAD_AMSERIAL_H
#define TOSTHREAD_AMSERIAL_H

#include "message.h"
#include "TinyError.h"

#ifndef AM_RECEIVE_FROM_ANY
#define AM_RECEIVE_FROM_ANY   0XFF
#endif

extern error_t amSerialStart();
extern error_t amSerialStop();

extern error_t amSerialReceive(message_t* m, uint32_t timeout, am_id_t amId);
extern error_t amSerialSend(am_addr_t addr, message_t* msg, uint8_t len, am_id_t amId);

extern am_addr_t  amSerialLocalAddress(); 
extern am_group_t amSerialGetLocalGroup();
extern am_addr_t  amSerialGetDestination(message_t* amsg);
extern am_addr_t  amSerialGetSource(message_t* amsg);
extern void       amSerialSetDestination(message_t* amsg, am_addr_t addr);
extern void       amSerialSetSource(message_t* amsg, am_addr_t addr);
extern bool       amSerialIsForMe(message_t* amsg);
extern am_id_t    amSerialGetType(message_t* amsg);
extern void       amSerialSetType(message_t* amsg, am_id_t t);
extern am_group_t amSerialGetGroup(message_t* amsg);
extern void       amSerialSetGroup(message_t* amsg, am_group_t grp);

extern void    serialClear(message_t* msg);
extern uint8_t serialGetPayloadLength(message_t* msg);
extern void    serialSetPayloadLength(message_t* msg, uint8_t len);
extern uint8_t serialMaxPayloadLength();
extern void*   serialGetPayload(message_t* msg, uint8_t len);

extern error_t serialRequestAck( message_t* msg );
extern error_t serialNoAck( message_t* msg );
extern bool    serialWasAcked(message_t* msg);
#endif //TOSTHREAD_AMSERIAL_H
