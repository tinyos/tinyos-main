/*
 * Copyright (c) 2014, Technische Universitaet Berlin
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
 * ========================================================================
 */

#ifndef TSSM_UTILS_H
#define TSSM_UTILS_H

// 62.5 khz
/*
#define ALARM62_SECOND 62500
#define TIMER_MILLI_SECOND 1024
// max(dt) = 65535us = approx 4 timeslots at 15ms ! One tick is 16us
// scale with 65536 = 62500 * 1024 * 1024 / 1000000 <- TinyOS uses binary second values
#define TSSM_ALARM62_TIME_FROM_US(dt) (((dt) * 65536UL) / (1000000UL))
#define TSSM_ALARM62_START_US(dt) call TssmAlarm62.start( (((dt) * 65536UL) / (1000000UL)) )
#define TSSM_ALARM62_START_AT_US(t0, dt) call TssmAlarm62.startAt( (t0), (((dt) * 65536UL) / (1000000UL)) )
// make big time jumps in ms -> max(dt) = 68719ms = 68.7s = approx 4000 timeslots at 15ms with less precision
// scale with 64000 = 62500 * 1024 / 1000 <- TinyOS uses binary second values
#define TSSM_ALARM62_START_MS(dt) call TssmAlarm62.start( (((dt) * 64000UL) / 1000UL) )
*/

#define TSSM_ALARM32_TIME_FROM_US_IS_TOO_BIG(dt) ( (bool) (dt > 0x7FFFFFUL) )
#define TSSM_ALARM32_TIME_FROM_US(dt) (( dt << 9 ) / 15625UL )
#define TSSM_ALARM32_TIME_FROM_US_ERROR(dt) ( ((dt << 9) % 15625UL) >> 9 )

#define TSSM_ALARM32_TIME_TO_US_IS_TOO_BIG(dt) ((bool) (dt > 274877UL) )
#define TSSM_ALARM32_TIME_TO_US(dt)   (( dt * 15625UL)  >> 9 )
#define TSSM_ALARM32_TIME_TO_US_ERROR(dt) (( dt * 15625UL)  & 0x1ff )

#define TSSM_ALARM32_START_US(dt) ( call TssmAlarm32.start( TSSM_ALARM32_TIME_FROM_US(dt) ))
#define TSSM_ALARM32_START_AT_US(t0, dt) ( call TssmAlarm32.startAt( (t0), TSSM_ALARM32_TIME_FROM_US(dt) ))

#define TSSM_SYMBOLS_TO_US(dt)   ( (uint32_t) (dt << 4) )
#define TSSM_SYMBOLS_FROM_US(dt) ( (uint32_t) (dt >> 4) )
#define TSSM_SYMBOLS_FROM_US_ERROR(dt) ((uint32_t)(dt & 0x0f))

#define TSSM_32KHZ_FROM_SYMBOLS_IS_TOO_BIG(dt) ((bool) (dt > 0x1ffffff ))
#define TSSM_32KHZ_FROM_SYMBOLS(dt) ((dt << 7) / 15625UL )
#define TSSM_32KHZ_TO_SYMBOLS_IS_TOO_BIG(dt) ((bool) (dt > 274877UL) )
#define TSSM_32KHZ_TO_SYMBOLS(dt) ((dt * 15625UL) >> 7 )
#define TSSM_32KHZ_TO_SYMBOLS_ERROR(dt) ((dt * 15625UL) & 0x7f )

// make big time jumps in ms -> max(dt) = 128001ms = 128s = approx 8533 timeslots at 15ms with less precision
// scale with 33554 = 32768 * 1024 / 1000 <- TinyOS uses binary second values
// remainder: 0.432, error: ??
#define TSSM_ALARM32_START_MS(dt) ( call TssmAlarm32.start( (((dt) * 32768UL) / 1000UL) ) )
#define TSSM_ALARM32_START_AT_MS(t0, dt) ( call TssmAlarm32.startAt( (t0), (((dt) * 32768UL) / 1000UL)) )


#define TSSM_REPORT_ERROR(t, e)  \
/*call Leds.led0On();*/ call DebugHelper.setErrorIndicator(); \
if (ErrorReport.time == 0) { \
  atomic { \
    ErrorReport.time = (t); \
    ErrorReport.error = (e); \
  } \
} \
post reportError();

enum tsch_state_e {
  TSCH_STATE_NONE         = 0x00,
  TSCH_STATE_INIT         = 0x01,
  TSCH_STATE_IDLE         = 0x02,
  TSCH_STATE_SLOT_START   = 0x03,
  TSCH_STATE_SLOT_PREPARE = 0x04,
  TSCH_STATE_SLOT_CLEANUP = 0x05,
  TSCH_STATE_SLOT_END     = 0x06,

  TSCH_STATE_TXDATA_WAIT_PREPARE = 0x10,
  TSCH_STATE_TXDATA_PREPARE      = 0x11,
  TSCH_STATE_TXDATA_HW_SCHEDULED = 0x12,
  TSCH_STATE_TXDATA_SUCCESS      = 0x13,
  TSCH_STATE_RXACK_PREPARE       = 0x14,
  TSCH_STATE_RXACK_HW_SCHEDULED  = 0x15,
  TSCH_STATE_RXACK_SUCCESS       = 0x16,

  TSCH_STATE_RXDATA_WAIT_PREPARE = 0x20,
  TSCH_STATE_RXDATA_PREPARE      = 0x21,
  TSCH_STATE_RXDATA_HW_SCHEDULED = 0x22,
  TSCH_STATE_RXDATA_SUCCESS      = 0x23,
  TSCH_STATE_TXACK_PREPARE       = 0x24,
  TSCH_STATE_TXACK_HW_SCHEDULED  = 0x25,
  TSCH_STATE_TXACK_SUCCESS       = 0x26,

  TSCH_STATE_TXDATA_FAIL = 0xA0,
  TSCH_STATE_RXACK_FAIL  = 0xA1,
  TSCH_STATE_RXDATA_FAIL = 0xA2,
  TSCH_STATE_TXACK_FAIL  = 0xA3
};

enum tsch_slot_type_e {
  TSCH_SLOT_TYPE_OFF = 0,
  TSCH_SLOT_TYPE_RX,
  TSCH_SLOT_TYPE_TX,
  TSCH_SLOT_TYPE_SHARED,
  TSCH_SLOT_TYPE_ADVERTISEMENT
};

enum tsch_error_e {
  TSCH_ERROR_NONE = 0,
  TSCH_ERROR_UNHANDLED_ALARM_STATE = 1
};

typedef uint8_t tknfsm_delaytype_t;
typedef uint8_t tknfsm_delay_time_t;

enum tsch_delay_type_e {
  TSCH_DELAY_NONE = 0,
  TSCH_DELAY_IMMEDIATE = 1,
//  TSCH_DELAY_MICROWAIT, // TODO micro-waits should probably happen within event handlers
  TSCH_DELAY_SHORT,
  TSCH_DELAY_LONG
};

enum tsch_event_e {
  TSCH_EVENT_INIT_DONE      = 0x01,
  TSCH_EVENT_START_SLOT     = 0x02,
  TSCH_EVENT_END_SLOT       = 0x03,
  TSCH_EVENT_SLOT_ENDED     = 0x04,
  TSCH_EVENT_INIT_ADV       = 0x10,
  TSCH_EVENT_INIT_ADV_DONE  = 0x11,
  TSCH_EVENT_INIT_TX        = 0x12,
  TSCH_EVENT_INIT_TX_DONE   = 0x13,
  TSCH_EVENT_INIT_RX        = 0x14,
  TSCH_EVENT_INIT_RX_DONE   = 0x15,
  TSCH_EVENT_CLEANUP_ADV    = 0x16,
  TSCH_EVENT_CLEANUP_TX     = 0x17,
  TSCH_EVENT_CLEANUP_RX     = 0x18,
  TSCH_EVENT_PREPARE_TXDATA = 0x20,
  TSCH_EVENT_TXDATA         = 0x21,
  TSCH_EVENT_PREPARE_TXACK  = 0x22,
  TSCH_EVENT_TXACK          = 0x23,
  TSCH_EVENT_TX_SUCCESS     = 0x24,
  TSCH_EVENT_PREPARE_RXDATA = 0x25,
  TSCH_EVENT_RXDATA         = 0x26,
  TSCH_EVENT_PREPARE_RXACK  = 0x27,
  TSCH_EVENT_RXACK          = 0x28,
  TSCH_EVENT_RX_SUCCESS     = 0x29,
  TSCH_EVENT_TX_FAILED      = 0xA0,
  TSCH_EVENT_RX_FAILED      = 0xA1,
};

enum tsch_event_handler_e {
  TKNTSCH_HANDLER_SLOT_START = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_ADV_INIT = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TX_INIT = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RX_INIT = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXDATA_WAIT_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXDATA_WAIT_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXDATA_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXDATA_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXDATA_HW_SCHEDULED = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXDATA_HW_SCHEDULED = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXDATA_SUCCESS = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXDATA_SUCCESS = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXACK_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXACK_PREPARE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXACK_HW_SCHEDULED = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXACK_HW_SCHEDULED = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXACK_SUCCESS = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXACK_SUCCESS = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_ADV_CLEANUP = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TX_CLEANUP = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RX_CLEANUP = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_SLOT_END = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_IDLE = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXDATA_FAIL = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXDATA_FAIL = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_RXACK_FAIL = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_TXACK_FAIL = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_INIT = unique("TknTschTssm.eventHandler"),
  TKNTSCH_HANDLER_INIT_DONE = unique("TknTschTssm.eventHandler"),
};

#define TSSM_EVENT_TABLE_INIT { \
      /* current state */             /* event */                /* new state before handler */  /* event handler */ \
    /* normal slot operation */ \
    { TSCH_STATE_IDLE,                TSCH_EVENT_START_SLOT,     TSCH_STATE_SLOT_START,          TKNTSCH_HANDLER_SLOT_START }, \
    { TSCH_STATE_SLOT_START,          TSCH_EVENT_INIT_ADV,       TSCH_STATE_SLOT_PREPARE,        TKNTSCH_HANDLER_ADV_INIT }, \
    { TSCH_STATE_SLOT_START,          TSCH_EVENT_INIT_TX,        TSCH_STATE_SLOT_PREPARE,        TKNTSCH_HANDLER_TX_INIT }, \
    { TSCH_STATE_SLOT_START,          TSCH_EVENT_INIT_RX,        TSCH_STATE_SLOT_PREPARE,        TKNTSCH_HANDLER_RX_INIT }, \
    { TSCH_STATE_SLOT_PREPARE,        TSCH_EVENT_INIT_ADV_DONE,  TSCH_STATE_TXDATA_WAIT_PREPARE, TKNTSCH_HANDLER_TXDATA_WAIT_PREPARE }, \
    { TSCH_STATE_SLOT_PREPARE,        TSCH_EVENT_INIT_TX_DONE,   TSCH_STATE_TXDATA_WAIT_PREPARE, TKNTSCH_HANDLER_TXDATA_WAIT_PREPARE }, \
    { TSCH_STATE_SLOT_PREPARE,        TSCH_EVENT_INIT_RX_DONE,   TSCH_STATE_RXDATA_WAIT_PREPARE, TKNTSCH_HANDLER_RXDATA_WAIT_PREPARE }, \
    { TSCH_STATE_TXDATA_WAIT_PREPARE, TSCH_EVENT_PREPARE_TXDATA, TSCH_STATE_TXDATA_PREPARE,      TKNTSCH_HANDLER_TXDATA_PREPARE }, \
    { TSCH_STATE_RXDATA_WAIT_PREPARE, TSCH_EVENT_PREPARE_RXDATA, TSCH_STATE_RXDATA_PREPARE,      TKNTSCH_HANDLER_RXDATA_PREPARE }, \
    { TSCH_STATE_TXDATA_PREPARE,      TSCH_EVENT_TXDATA,         TSCH_STATE_TXDATA_HW_SCHEDULED, TKNTSCH_HANDLER_TXDATA_HW_SCHEDULED }, \
    { TSCH_STATE_RXDATA_PREPARE,      TSCH_EVENT_RXDATA,         TSCH_STATE_RXDATA_HW_SCHEDULED, TKNTSCH_HANDLER_RXDATA_HW_SCHEDULED }, \
    { TSCH_STATE_TXDATA_HW_SCHEDULED, TSCH_EVENT_TX_SUCCESS,     TSCH_STATE_TXDATA_SUCCESS,      TKNTSCH_HANDLER_TXDATA_SUCCESS }, \
    { TSCH_STATE_RXDATA_HW_SCHEDULED, TSCH_EVENT_RX_SUCCESS,     TSCH_STATE_RXDATA_SUCCESS,      TKNTSCH_HANDLER_RXDATA_SUCCESS }, \
    { TSCH_STATE_TXDATA_SUCCESS,      TSCH_EVENT_PREPARE_RXACK,  TSCH_STATE_RXACK_PREPARE,       TKNTSCH_HANDLER_RXACK_PREPARE }, \
    { TSCH_STATE_RXDATA_SUCCESS,      TSCH_EVENT_PREPARE_TXACK,  TSCH_STATE_TXACK_PREPARE,       TKNTSCH_HANDLER_TXACK_PREPARE }, \
    { TSCH_STATE_RXACK_PREPARE,       TSCH_EVENT_RXACK,          TSCH_STATE_RXACK_HW_SCHEDULED,  TKNTSCH_HANDLER_RXACK_HW_SCHEDULED }, \
    { TSCH_STATE_TXACK_PREPARE,       TSCH_EVENT_TXACK,          TSCH_STATE_TXACK_HW_SCHEDULED,  TKNTSCH_HANDLER_TXACK_HW_SCHEDULED }, \
    { TSCH_STATE_RXACK_HW_SCHEDULED,  TSCH_EVENT_RX_SUCCESS,     TSCH_STATE_RXACK_SUCCESS,       TKNTSCH_HANDLER_RXACK_SUCCESS }, \
    { TSCH_STATE_TXACK_HW_SCHEDULED,  TSCH_EVENT_TX_SUCCESS,     TSCH_STATE_TXACK_SUCCESS,       TKNTSCH_HANDLER_TXACK_SUCCESS }, \
    { TKNFSM_STATE_ANY,               TSCH_EVENT_CLEANUP_ADV,    TSCH_STATE_SLOT_CLEANUP,        TKNTSCH_HANDLER_ADV_CLEANUP }, \
    { TKNFSM_STATE_ANY,               TSCH_EVENT_CLEANUP_TX,     TSCH_STATE_SLOT_CLEANUP,        TKNTSCH_HANDLER_TX_CLEANUP }, \
    { TKNFSM_STATE_ANY,               TSCH_EVENT_CLEANUP_RX,     TSCH_STATE_SLOT_CLEANUP,        TKNTSCH_HANDLER_RX_CLEANUP }, \
    { TSCH_STATE_SLOT_CLEANUP,        TSCH_EVENT_END_SLOT,       TSCH_STATE_SLOT_END,            TKNTSCH_HANDLER_SLOT_END }, \
    { TSCH_STATE_SLOT_END,            TSCH_EVENT_SLOT_ENDED,     TSCH_STATE_IDLE,                TKNTSCH_HANDLER_IDLE }, \
    /* error handling -> cleanup -> slot end */ \
    { TSCH_STATE_TXDATA_HW_SCHEDULED, TSCH_EVENT_TX_FAILED,      TSCH_STATE_TXDATA_FAIL,         TKNTSCH_HANDLER_TXDATA_FAIL }, \
    { TSCH_STATE_RXDATA_HW_SCHEDULED, TSCH_EVENT_RX_FAILED,      TSCH_STATE_RXDATA_FAIL,         TKNTSCH_HANDLER_RXDATA_FAIL }, \
    { TSCH_STATE_TXACK_PREPARE,       TSCH_EVENT_TX_FAILED,      TSCH_STATE_TXACK_FAIL,          TKNTSCH_HANDLER_TXACK_FAIL }, \
    { TSCH_STATE_RXACK_PREPARE,       TSCH_EVENT_RX_FAILED,      TSCH_STATE_RXACK_FAIL,          TKNTSCH_HANDLER_RXACK_FAIL }, \
    { TSCH_STATE_RXACK_HW_SCHEDULED,  TSCH_EVENT_RX_FAILED,      TSCH_STATE_RXACK_FAIL,          TKNTSCH_HANDLER_RXACK_FAIL }, \
    { TSCH_STATE_TXACK_HW_SCHEDULED,  TSCH_EVENT_TX_FAILED,      TSCH_STATE_TXACK_FAIL,          TKNTSCH_HANDLER_TXACK_FAIL }, \
    { TKNFSM_STATE_ANY,               TSCH_EVENT_END_SLOT,       TSCH_STATE_SLOT_END,            TKNTSCH_HANDLER_SLOT_END }, \
    /* init */ \
    { TKNFSM_STATE_INIT,              TKNFSM_EVENT_INIT,         TSCH_STATE_INIT,                TKNTSCH_HANDLER_INIT }, /* global TSSM init */ \
    { TKNFSM_STATE_NONE,              TKNFSM_EVENT_INIT,         TSCH_STATE_INIT,                TKNTSCH_HANDLER_INIT }, /* global TSSM init */ \
    { TSCH_STATE_INIT,                TKNFSM_EVENT_INIT,         TSCH_STATE_INIT,                TKNTSCH_HANDLER_INIT }, /* global TSSM init */ \
    { TSCH_STATE_INIT,                TSCH_EVENT_INIT_DONE,      TSCH_STATE_IDLE,                TKNTSCH_HANDLER_INIT_DONE }, /* schedule first SLOT_START */ \
  }

#endif /* TSSM_UTILS_H */
