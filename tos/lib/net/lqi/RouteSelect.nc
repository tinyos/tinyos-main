// $Id: RouteSelect.nc,v 1.1 2007-02-15 01:27:26 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * Authors:		Philip Levis
 * Date last modified:  8/12/02
 *
 * The RouteSelect interface is part of the TinyOS ad-hoc routing
 * system architecture. The component that keeps track of routing
 * information and makes route selection decisions provides this
 * interface. When a Send component wants to send a packet, it passes
 * it to RouteSelect for its routing information to be filled in. This
 * way, the Send component is entirely unaware of the routing
 * header/footer structure.
 */

/**
 * Interface to a route selection component in the TinyOS ad-hoc
 * system architecture.
 * @author Philip Levis
 */

#include "AM.h"

interface RouteSelect {

  /**
   * Whether there is currently a valid route.
   *
   * @return Whether there is a valid route.
   */
  command bool isActive();

  /**
   * Select a route and fill in all of the necessary routing
   * information to a packet.
   *
   * @param msg Message to select route for and fill in routing information.
   *
   * @return Whether a route was selected succesfully. On FAIL the
   * packet should not be sent.
   *
   */
  
  command error_t selectRoute(message_t* msg, uint8_t resend);


  /**
   * Given a TOS_MstPtr, initialize its routing fields to a known
   * state, specifying that the message is originating from this node.
   * This known state can then be used by selectRoute() to fill in
   * the necessary data.
   *
   * @param msg Message to select route for and fill in init data.
   *
   * @return Should always return SUCCESS.
   *
   */

  command error_t initializeFields(message_t* msg);
  
  
  /**
   * Given a TinyOS message buffer, provide a pointer to the data
   * buffer within it that an application can use as well as its
   * length. Unlike the getBuffer of the Send interface, this can
   * be called freely and does not modify the buffer.
   *
   * @param msg The message to get the data region of.
   *
   * @param length Pointer to a field to store the length of the data region.
   *
   * @return A pointer to the data region.
   */
  
  command uint8_t* getBuffer(message_t* msg, uint16_t* len);
}
