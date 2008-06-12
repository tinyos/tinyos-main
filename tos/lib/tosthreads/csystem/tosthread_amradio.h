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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */
 
#ifndef TOSTHREAD_AMRADIO_H
#define TOSTHREAD_AMRADIO_H

#include "message.h"
#include "AM.h"
#include "TinyError.h"

#ifndef AM_RECEIVE_FROM_ANY
#define AM_RECEIVE_FROM_ANY   0XFF
#endif

extern error_t amRadioStart();
extern error_t amRadioStop();

extern error_t amRadioReceive(message_t* m, uint32_t timeout, am_id_t amId);
extern error_t amRadioSnoop(message_t* m, uint32_t timeout, am_id_t amId);
extern error_t amRadioSend(am_addr_t addr, message_t* msg, uint8_t len, am_id_t amId);

extern am_addr_t  amRadioGetLocalAddress(); 
extern am_group_t amRadioGetLocalGroup();
extern am_addr_t  amRadioGetDestination(message_t* amsg);
extern am_addr_t  amRadioGetSource(message_t* amsg);
extern void       amRadioSetDestination(message_t* amsg, am_addr_t addr);
extern void       amRadioSetSource(message_t* amsg, am_addr_t addr);
extern bool       amRadioIsForMe(message_t* amsg);
extern am_id_t    amRadioGetType(message_t* amsg);
extern void       amRadioSetType(message_t* amsg, am_id_t t);
extern am_group_t amRadioGetGroup(message_t* amsg);
extern void       amRadioSetGroup(message_t* amsg, am_group_t grp);
 
extern void    radioClear(message_t* msg);
extern uint8_t radioGetPayloadLength(message_t* msg);
extern void    radioSetPayloadLength(message_t* msg, uint8_t len);
extern uint8_t radioMaxPayloadLength();
extern void*   radioGetPayload(message_t* msg, uint8_t len);

extern error_t radioRequestAck( message_t* msg );
extern error_t radioNoAck( message_t* msg );
extern bool    radioWasAcked(message_t* msg);

#endif //TOSTHREAD_AMRADIO_H
