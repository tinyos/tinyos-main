/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Description ---------------------------------------------------------
 * Macros for configuring the TDA5250.
 * - Revision ------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * Author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#ifndef TDA5250CONTROL_H
#define TDA5250CONTROL_H

typedef enum {
  RADIO_MODE_ON_TRANSITION,
  RADIO_MODE_ON,
  RADIO_MODE_OFF_TRANSITION,
  RADIO_MODE_OFF,
  RADIO_MODE_TX_TRANSITION,
  RADIO_MODE_TX,
  RADIO_MODE_RX_TRANSITION,
  RADIO_MODE_RX,
  RADIO_MODE_CCA_TRANSITION,
  RADIO_MODE_CCA,
  RADIO_MODE_TIMER_TRANSITION,
  RADIO_MODE_TIMER,
  RADIO_MODE_SELF_POLLING_TRANSITION,
  RADIO_MODE_SELF_POLLING,
  RADIO_MODE_SLEEP_TRANSITION,
  RADIO_MODE_SLEEP
} radioMode_t;

#define INIT_RSSI_THRESHOLD     26
#define TH1_VALUE               0x0000
#define TH2_VALUE               0xFFFF

#endif //TDA5250CONTROL_H
