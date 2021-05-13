/*
 * Copyright (c) 2006 Washington University in St. Louis.
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
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.17 $
 * @date $Date: 2010-06-29 22:07:50 $
 */

#ifndef PRINTF_H
#define PRINTF_H

#ifndef NEW_PRINTF_SEMANTICS
#warning \
"                                  *************************** PRINTF SEMANTICS HAVE CHANGED! ********************************************* Make sure you now include the following two components in your top level application file: PrintfC and SerialStartC. To supress this warning in the future, #define the variable NEW_PRINTF_SEMANTICS. Take a look at the updated tutorial application under apps/tutorials/printf for an example. ************************************************************************************"
#endif

#ifndef PRINTF_BUFFER_SIZE
#define PRINTF_BUFFER_SIZE 250 
#endif

#if PRINTF_BUFFER_SIZE > 255
  #define PrintfQueueC	BigQueueC
  #define PrintfQueue	BigQueue
#else
  #define PrintfQueueC	QueueC
  #define PrintfQueue	Queue
#endif

#if defined (_H_msp430hardware_h) || defined (_H_atmega128hardware_H)
  #include <stdio.h>
#else
#ifdef __M16C60HARDWARE_H__ 
  #include "m16c60_printf.h"
#else
  #include "generic_printf.h"
#endif
#endif
#undef putchar

#include "message.h"
#include "debug.h"
int printfflush();

#ifndef PRINTF_MSG_LENGTH
#define PRINTF_MSG_LENGTH	28
#endif
typedef nx_struct printf_msg {
  nx_uint8_t buffer[PRINTF_MSG_LENGTH];
} printf_msg_t;

enum {
  AM_PRINTF_MSG = 100,
};




#endif //PRINTF_H

