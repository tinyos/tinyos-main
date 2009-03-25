/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
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
 * $Revision: 1.2 $
 * $Date: 2009-03-25 16:47:49 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "printf.h"
#include <stdio.h>
#ifdef __STDC__
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#if defined(PLATFORM_TELOSB)
#include <UserButton.h>
#endif

module DebugP {
  uses {
    interface Boot;
    interface Leds;
#if defined(PLATFORM_TELOSB)
    interface Notify<button_state_t> as ButtonPressed;
#endif
  }
}
implementation {

  enum {
    MAX_LEN_FUNNAME = 50,
    MAX_LEN_FILENAME = 50,
    NUM_LIST_ENTRIES = 20,
  };

  typedef struct {
    const char *filename;
    uint16_t line;
    const char *format;
    uint32_t param[2];
  } debug_list_entry_t;

  norace debug_list_entry_t m_list[NUM_LIST_ENTRIES];
  norace uint8_t m_head;
  norace uint8_t m_tail;
  norace bool m_overflow;


  uint16_t m_assertCounter;
  norace uint16_t m_assertLine;
  norace char m_assertFilename[MAX_LEN_FILENAME];
  norace char m_assertFunction[MAX_LEN_FUNNAME];

  event void Boot.booted() {
#if defined(PLATFORM_TELOSB)
    call ButtonPressed.enable();
#endif
  }

#if defined(PLATFORM_TELOSB)
  event void ButtonPressed.notify( button_state_t val )
  {
    dbg_serial_flush();
  }
#endif

  task void assertFailTask()
  {
    if (m_assertCounter == 0) {
      printf("Assert failed: File: %s, line: %d, function: %s.\n", m_assertFilename, m_assertLine, m_assertFunction);
      printfflush();
    }
    if (m_assertCounter++ < 3000) {
      call Leds.led0On(); 
      call Leds.led1On(); 
      call Leds.led2On(); 
    } else {
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2Off(); 
    }
    if (m_assertCounter > 6000)
      m_assertCounter = 0;
    post assertFailTask();
  }

  void tkn154_assert(bool val, const char *filename, uint16_t line, const char *func) @C() @spontaneous()
  {
    if (!val) {
      if (m_assertLine == 0) {
        // only catch the first failure, output it periodically
        m_assertLine = line;
        strncpy(m_assertFilename, filename, MAX_LEN_FILENAME);
        strncpy(m_assertFunction, func, MAX_LEN_FILENAME);
        post assertFailTask();
      }
    }
  }

  void tkn154_dbg_serial(const char *filename, uint16_t line, ...) @C() @spontaneous()
  { 
    // This function must be fast: we just copy the strings and 
    // output them later in the flush-function 

    if ((m_head + 1) % NUM_LIST_ENTRIES != m_tail) {
      va_list argp;

      m_list[m_head].filename = filename;
      m_list[m_head].line = line;
      va_start(argp, line);
      m_list[m_head].format = va_arg(argp, char*);
      m_list[m_head].param[0] = va_arg(argp, uint32_t);
      m_list[m_head].param[1] = va_arg(argp, uint32_t);
      va_end(argp);
      m_head = (m_head  + 1) % NUM_LIST_ENTRIES;
    } else
      m_overflow = TRUE;
  }

  task void serialFlushTask()
  {
    if (m_overflow)
      printf("SERIAL OVERFLOW!\n");
    if (m_head != m_tail) {
      printf("%s:%d:", m_list[m_tail].filename, m_list[m_tail].line);
      printf(m_list[m_tail].format, m_list[m_tail].param[0], m_list[m_tail].param[1]);
      atomic {
        if (++m_tail >= NUM_LIST_ENTRIES)
          m_tail = 0;
      }
    }
    if (m_head != m_tail)
      post serialFlushTask();
    printfflush();
  }

  void tkn154_dbg_serial_flush() @C() @spontaneous()
  {
    post serialFlushTask();
  }
}
