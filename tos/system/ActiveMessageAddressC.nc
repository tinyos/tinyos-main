// $Id: ActiveMessageAddressC.nc,v 1.10 2010-06-29 22:07:56 scipio Exp $
/*
 * Copyright (c) 2004-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 *
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 * Date last modified:  $Id: ActiveMessageAddressC.nc,v 1.10 2010-06-29 22:07:56 scipio Exp $
 *
 */

/**
 * Component that stores the node's active message address and group ID.
 *
 * @author Philip Levis
 * @author David Moss
 */

module ActiveMessageAddressC @safe() {
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
   * @param group The node's group ID
   * @param addr The node's active message address
   */
  async command void ActiveMessageAddress.setAddress(am_group_t myGroup, am_addr_t myAddr) {
    atomic {
      addr = myAddr;
      group = myGroup;
    }
    signal ActiveMessageAddress.changed();
  }
  
    
  /**
   * @return the group address of this node
   */
  async command am_group_t ActiveMessageAddress.amGroup() {
    am_group_t myGroup;
    atomic myGroup = group;
    return myGroup;
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
   * @deprecated Use ActiveMessageAddress.setAddress() instead
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
