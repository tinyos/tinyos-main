/* $Id: platform_message.h,v 1.5 2007-06-12 11:02:35 andreaskoepke Exp $
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Defining the platform-independently named packet structures to be the
 * chip-specific TDA5250 packet structures.
 *
 * @author Philip Levis
 * @author Vlado Handziski (TDA5250 Modifications)
 * @date   May 16 2005
 * Revision:  $Revision: 1.5 $
 */


#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include "Serial.h"
#include "tda5250_message.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 48
#endif

typedef union message_header_t {
  tda5250_header_t radio;
  serial_header_t serial;
} message_header_t;

typedef union message_footer_t {
  tda5250_footer_t radio;
} message_footer_t;

typedef union message_metadata_t {
  tda5250_metadata_t radio;
} message_metadata_t;

typedef tda5250_header_t message_radio_header_t;
typedef tda5250_footer_t message_radio_footer_t;
typedef tda5250_metadata_t message_radio_metadata_t;

#if TOSH_DATA_LENGTH < 33
#error "TOSH_DATA_LENGH must be larger than 33 bytes for this platform."
#endif

#endif
