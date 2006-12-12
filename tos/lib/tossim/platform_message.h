// $Id: platform_message.h,v 1.4 2006-12-12 18:23:35 vlahan Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 *
 */
 
/**
 * Defining the platform-independently named packet structures to be the
 * tossim structures.
 *
 * @author Philip Levis
 * @date   Dec 2 2005
 * Revision:  $Revision: 1.4 $
 */


#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <TossimRadioMsg.h>
#include <Serial.h>

typedef union message_header {
  tossim_header_t tossim;
  serial_header_t serial;
} message_header_t;

typedef union message_footer {
  tossim_footer_t tossim;
} message_footer_t;

typedef union message_metadata {
  tossim_metadata_t tossim;
} message_metadata_t;

#endif
