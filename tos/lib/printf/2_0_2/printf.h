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
 * @version $Revision: 1.1 $
 * @date $Date: 2008-06-12 12:33:47 $
 */

#ifndef PRINTF_H
#define PRINTF_H

#ifndef PRINTF_BUFFER_SIZE
#define PRINTF_BUFFER_SIZE  250
#endif

#ifdef _H_msp430hardware_h
  #include <stdio.h>
#endif
#ifdef _H_atmega128hardware_H
  #include "avr_stdio.h"
#endif
#include "message.h"

typedef nx_struct printf_msg {
  nx_uint8_t buffer[TOSH_DATA_LENGTH];
} printf_msg_t;

enum {
  AM_PRINTF_MSG = 100,
};

#endif //PRINTF_H

