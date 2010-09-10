// $Id: LocalIeeeEui64C.nc,v 1.1 2010/02/23 06:45:38 sdhsdh Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 *  Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 *  Dummy Extended Address for micaz
 */

#include "IeeeEui64.h"

module LocalIeeeEui64C {
  provides interface LocalIeeeEui64;
} implementation {
  command ieee_eui64_t LocalIeeeEui64.getId() {
    ieee_eui64_t id;
    /* this is UCB's OUI */
    id.data[0] = 0x00;
    id.data[1] = 0x12;
    id.data[2] = 0x6d;

    /* UCB will let anyone use this OUI so long as these two octets
       are 'LO' -- "local".  All other octets are reserved.  */
    /* SDH -- 9/10/2010 */
    id.data[3] = 'L';
    id.data[4] = 'O';

    id.data[5] = 0;
    id.data[6] = TOS_NODE_ID >> 8;
    id.data[7] = TOS_NODE_ID & 0xff;
    return id;
  }
}
