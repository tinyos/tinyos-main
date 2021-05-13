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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 *
 * ========================================================================
 */

#ifndef STATIC_CONFIG_H
#define STATIC_CONFIG_H

#ifndef TKNTSCH_SLOTFRAME_6TSCH_LENGTH
#define TKNTSCH_SLOTFRAME_6TSCH_LENGTH 101
#endif

#define TKNTSCH_TIMESLOT_TEMPLATE_6TSCH_DEFAULT_INITIALIZER() { \
    0,     /* template id */ \
    1800,  /* tsCCAOffset */ \
    128,   /* tsCCA */ \
    2120,  /* tsTxOffset */ \
    1120,  /* tsRxOffset */ \
    800,  /* tsRxAckDelay */ \
    1000,  /* tsTxAckDelay */ \
    2200,  /* tsRxWait */ \
    400,   /* tsAckWait */ \
    192,   /* tsRxTx */ \
    2400,  /* tsMaxAck */ \
    4256,  /* tsMaxTx */ \
    10000, /* Time Slot duration */ \
  }

/* Default IEEE 802.15.4e hopping sequences, obtained from https://gist.github.com/twatteyne/2e22ee3c1a802b685695 */
#define TSCH_HOPPING_SEQUENCE_16_16 {16, 17, 23, 18, 26, 15, 25, 22, 19, 11, 12, 13, 24, 14, 20, 21}
#define TSCH_HOPPING_SEQUENCE_1_1   {16}
#define TSCH_HOPPING_SEQUENCE TSCH_HOPPING_SEQUENCE_1_1

#define TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_INITIALIZER() { \
        0, /* slotframe handle */ \
        TKNTSCH_SLOTFRAME_6TSCH_LENGTH /* slotframe length */ \
        }
#define TKNTSCH_SLOTFRAME_6TSCH_DEFAULT_ACTIVE_SLOTS 1

#define TKNTSCH_BROADCAST_CELL_ADDRESS() { PLAIN154_ADDR_EXTENDED, { 0x00 } }
//#define TKNTSCH_EB_CELL_ADDRESS() { PLAIN154_ADDR_EXTENDED, { 0xffffffffffffffffULL } }
#define TKNTSCH_EB_CELL_ADDRESS() { PLAIN154_ADDR_SHORT, { 0xffff } }

#define TKNTSCH_CELL_ADDRESS1() { PLAIN154_ADDR_EXTENDED, { 0x0012740100010101ULL } }
#define TKNTSCH_CELL_ADDRESS2() { PLAIN154_ADDR_EXTENDED, { 0x0012740200020202ULL } }
#define TKNTSCH_CELL_ADDRESS3() { PLAIN154_ADDR_EXTENDED, { 0x0012740300030303ULL } }
#define TKNTSCH_GENERIC_SHARED_CELL() { 0xffff, 0, PLAIN154E_LINK_OPTION_TX | PLAIN154E_LINK_OPTION_RX \
                | PLAIN154E_LINK_OPTION_SHARED, PLAIN154E_LINK_TYPE_NORMAL, &BROADCAST_CELL_ADDRESS }
#define TKNTSCH_GENERIC_EB_CELL() { 0, 0, PLAIN154E_LINK_OPTION_TX, PLAIN154E_LINK_TYPE_ADVERTISING, \
                &EB_CELL_ADDRESS }

#endif /* STATIC_CONFIG_H */
