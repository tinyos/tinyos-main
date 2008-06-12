/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
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
