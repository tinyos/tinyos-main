// $Id: AMQueueEntryP.nc,v 1.4 2006-12-12 18:23:46 vlahan Exp $
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
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Internal AM component that fills in needed packet fields for the 
 * AMSend -> Send transformation.
 *
 * @author Philip Levis
 * @date   Jan 16 2006
 */ 

#include "AM.h"

generic module AMQueueEntryP(am_id_t amId) {
  provides interface AMSend;
  uses{
    interface Send;
    interface AMPacket;
  }
}

implementation {

  command error_t AMSend.send(am_addr_t dest,
			      message_t* msg,
			      uint8_t len) {
    call AMPacket.setDestination(msg, dest);
    call AMPacket.setType(msg, amId);
    return call Send.send(msg, len);
  }

  command error_t AMSend.cancel(message_t* msg) {
    return call Send.cancel(msg);
  }

  event void Send.sendDone(message_t* m, error_t err) {
    signal AMSend.sendDone(m, err);
  }
  
  command uint8_t AMSend.maxPayloadLength() {
    return call Send.maxPayloadLength();
  }

  command void* AMSend.getPayload(message_t* m) {
    return call Send.getPayload(m);
  }
  
}
