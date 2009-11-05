/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.13 $
 * @date $Date: 2009-11-05 12:25:51 $
 */

#ifndef PRINTF_H
#define PRINTF_H

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

#ifdef _H_msp430hardware_h
  #include <stdio.h>
#endif
#ifdef _H_atmega128hardware_H
  #include "avr_stdio.h"
#endif
#ifdef __M16C62PHARDWARE_H__ 
#include "m16c62p_printf.h"
#endif
#include "message.h"
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

