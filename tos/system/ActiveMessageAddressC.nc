// $Id: ActiveMessageAddressC.nc,v 1.6 2007-06-14 04:39:02 rincon Exp $
/*									tab:4
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 * Date last modified:  $Id: ActiveMessageAddressC.nc,v 1.6 2007-06-14 04:39:02 rincon Exp $
 *
 */

/**
 * Component that stores the node's active message address and group ID.
 *
 * @author Philip Levis
 * @author David Moss
 */

module ActiveMessageAddressC  {
  provides {
    interface ActiveMessageAddress;
    async command am_addr_t amAddress();
    async command void setAmAddress(am_addr_t a);
  }
}
implementation {

  /** Node address */
  am_addr_t addr = TOS_AM_ADDRESS;

  /** Group address */
  am_group_t group = TOS_AM_GROUP;
 
  
  /***************** ActiveMessageAddress Commands ****************/
  /**
   * @return the active message address of this node
   */
  async command am_addr_t ActiveMessageAddress.amAddress() {
    return call amAddress();
  }
  
  /**
   * Set the active message address of this node
   * @param a The target active message address
   */
  async command void ActiveMessageAddress.setAmAddress(am_addr_t a) {
    call setAmAddress(a);
  }
  
    
  /**
   * @return the group address of this node
   */
  async command am_group_t ActiveMessageAddress.amGroup() {
    am_group_t myGroup;
    atomic myGroup = group;
    return myGroup;
  }
  
  /**
   * Set the group address of this node
   * @param group The group address
   */
  async command void ActiveMessageAddress.setAmGroup(am_group_t myGroup) {
    atomic group = myGroup;
    signal ActiveMessageAddress.changed();
  }

  /***************** Deprecated Commands ****************/
  /**
   * Get the node's default AM address.
   * @return address
   * @deprecated Use ActiveMessageAddress.amAddress() instead
   */
  async command am_addr_t amAddress() {
    am_addr_t myAddr;
    atomic myAddr = addr;
    return myAddr;
  }
  
  /**
   * Set the node's default AM address.
   *
   * @param a - the address.
   * @deprecated Use ActiveMessageAddress.setAmAddress() instead
   */
  async command void setAmAddress(am_addr_t a) {
    atomic addr = a;
    signal ActiveMessageAddress.changed();
  }
  
  
  /***************** Defaults ****************/
  /**
   * Notification that the address of this node changed.
   */
  default async event void ActiveMessageAddress.changed() {
  }
  
}
