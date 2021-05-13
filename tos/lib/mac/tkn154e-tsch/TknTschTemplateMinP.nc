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

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_TEMPLATE_MIN
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

#include "tkntsch_pib.h"
#include "static_config.h" // slotframe and template
#include "tkntsch_lock.h"

#include "plain154_values.h"

module TknTschTemplateMinP
{
  provides {
    interface TknTschTemplate as Template;
    interface Init;
  }
}
implementation
{
  // Variables
  const macTimeslotTemplate_t min_6tsch_tmpl
        = TKNTSCH_TIMESLOT_TEMPLATE_6TSCH_DEFAULT_INITIALIZER();
  volatile tkntsch_lock_t lock = TKNTSCH_LOCK_FREE;

  // constants

  // Prototypes

  // Interface commands and events
  command error_t Init.init()
  {
    T_LOG_INIT("Initializing TknTschTemplateMinP\n"); T_LOG_FLUSH;
    atomic lock = TKNTSCH_LOCK_FREE;
    return SUCCESS;
  }

  async command macTimeslotTemplate_t* Template.acquire()
  {
    bool result;
    TKNTSCH_ACQUIRE_LOCK(lock, result);
    if (result == FALSE) return NULL;
    return (macTimeslotTemplate_t*) &min_6tsch_tmpl;
  }

  async command void Template.release()
  {
    TKNTSCH_RELEASE_LOCK(lock);
  }

  task void printTemplate()
  {
#ifdef TKN_TSCH_LOG_DEBUG
    volatile uint32_t tmp;
    for (tmp = 0; tmp < 300000; tmp++) {}
    T_LOG_DEBUG("printTemplate: 6tsch time slot template\n");
    T_LOG_DEBUG("  macTimeslotTemplateId: %u\n", min_6tsch_tmpl.macTimeslotTemplateId);
    T_LOG_DEBUG("  macTsCCAOffset: %u\n", min_6tsch_tmpl.macTsCCAOffset);
    T_LOG_DEBUG("  macTsCCA: %u\n", min_6tsch_tmpl.macTsCCA);
    T_LOG_DEBUG("  macTsTxOffset: %u\n", min_6tsch_tmpl.macTsTxOffset);
    T_LOG_DEBUG("  macTsRxOffset: %u\n", min_6tsch_tmpl.macTsRxOffset);
    T_LOG_FLUSH;
    for (tmp = 0; tmp < 300000; tmp++) {}
    T_LOG_DEBUG("  macTsRxAckDelay: %u\n", min_6tsch_tmpl.macTsRxAckDelay);
    T_LOG_DEBUG("  macTsTxAckDelay: %u\n", min_6tsch_tmpl.macTsTxAckDelay);
    T_LOG_DEBUG("  macTsRxWait: %u\n", min_6tsch_tmpl.macTsRxWait);
    T_LOG_DEBUG("  macTsAckWait: %u\n", min_6tsch_tmpl.macTsAckWait);
    T_LOG_DEBUG("  macTsRxTx: %u\n", min_6tsch_tmpl.macTsRxTx);
    T_LOG_DEBUG("  macTsMaxAck: %u\n", min_6tsch_tmpl.macTsMaxAck);
    T_LOG_DEBUG("  macTsMaxTx: %u\n", min_6tsch_tmpl.macTsMaxTx);
    T_LOG_DEBUG("  macTsTimeslotLength: %u\n", min_6tsch_tmpl.macTsTimeslotLength);
    T_LOG_FLUSH;
#endif
  }

  async command void Template.printTemplate() { post printTemplate(); }

}
