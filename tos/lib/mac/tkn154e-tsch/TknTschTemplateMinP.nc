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

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

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
    printf("Initializing TknTschTemplateMinP\n"); printfflush();
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
    volatile uint32_t tmp;
    for (tmp = 0; tmp < 300000; tmp++) {}
    printf("printTemplate: 6tsch time slot template\n");
    printf("  macTimeslotTemplateId: %u\n", min_6tsch_tmpl.macTimeslotTemplateId);
    printf("  macTsCCAOffset: %u\n", min_6tsch_tmpl.macTsCCAOffset);
    printf("  macTsCCA: %u\n", min_6tsch_tmpl.macTsCCA);
    printf("  macTsTxOffset: %u\n", min_6tsch_tmpl.macTsTxOffset);
    printf("  macTsRxOffset: %u\n", min_6tsch_tmpl.macTsRxOffset);
    printfflush();
    for (tmp = 0; tmp < 300000; tmp++) {}
    printf("  macTsRxAckDelay: %u\n", min_6tsch_tmpl.macTsRxAckDelay);
    printf("  macTsTxAckDelay: %u\n", min_6tsch_tmpl.macTsTxAckDelay);
    printf("  macTsRxWait: %u\n", min_6tsch_tmpl.macTsRxWait);
    printf("  macTsAckWait: %u\n", min_6tsch_tmpl.macTsAckWait);
    printf("  macTsRxTx: %u\n", min_6tsch_tmpl.macTsRxTx);
    printf("  macTsMaxAck: %u\n", min_6tsch_tmpl.macTsMaxAck);
    printf("  macTsMaxTx: %u\n", min_6tsch_tmpl.macTsMaxTx);
    printf("  macTsTimeslotLength: %u\n", min_6tsch_tmpl.macTsTimeslotLength);
    printfflush();
  }
  
  async command void Template.printTemplate() { post printTemplate(); }
  
}
