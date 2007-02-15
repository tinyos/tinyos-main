// $Id: RouteControl.nc,v 1.1 2007-02-15 01:27:26 scipio Exp $

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
 * Authors:	Phil Buonadonna
 * Rev:		$Id: RouteControl.nc,v 1.1 2007-02-15 01:27:26 scipio Exp $
 */

/** 
 * Control/Monitor interface to a routing component 
 * @author Phil Buonadonna
 */

interface RouteControl {

  /**
   * Get this node's present parent address.
   * 
   * @return The address of the parent
   */
  command uint16_t getParent();

  /** 
   * Get this node's depth in the network
   * 
   * @return The network depth.
   */
  command uint8_t getDepth();

 
  /**
   * Return length of the routing forwarding queue 
   *
   * @return The number of outstanding entries in the queue.
   */
  command uint8_t getOccupancy();

  /**
   * Get a measure of goodness for the current parent 
   * 
   * @return A value between 0-256 where 256 represent the best
   * goodness
   */
  command uint8_t getQuality();

  /** 
   * Set the routing componenets internal update interval.
   *
   * @param The duration, in seconds, of successive routing
   * updates.
   * 
   * @return SUCCESS if the operation succeeded.
   */
  command error_t setUpdateInterval(uint16_t Interval);

  /**
   * Queue a manual update of the routing state.  This may or may
   * not include the transmission of a message.
   *
   * @return SUCCESS if a route update was queued.
   */
  command error_t manualUpdate();
}
