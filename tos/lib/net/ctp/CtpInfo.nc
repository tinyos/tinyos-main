/* $Id: CtpInfo.nc,v 1.8 2010-06-29 22:07:49 scipio Exp $ */
/*
 * Copyright (c) 2005 The Regents of the University  of California.  
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
 */

/*
 *  @author Rodrigo Fonseca
 *  @author Philip Levis
 *  @date   $Date: 2010-06-29 22:07:49 $
 *  @see Net2-WG
 */

#include "AM.h"

interface CtpInfo {

  /**
   * Get the parent of the node in the tree.  The pointer is allocated
   * by the caller.  If the parent is invalid, return FAIL.  The
   * caller MUST NOT use the value in parent if the return is not
   * SUCCESS.
   */
  
  command error_t getParent(am_addr_t* parent);
  
  /**
   * Get the ETX for the current path to the root through the current
   * parent. Sets etx argument to ETX*10.  The pointer is allocated by
   * the caller.  If the parent is invalid, return FAIL (no info).
   * The caller MUST NOT use the value in parent if the return is not
   * SUCCESS. Calling getEtx at the root will set the etx argument to
   * 0.
   */
  
  command error_t getEtx(uint16_t* etx);

  /**
   * This informs the routing engine that sending a beacon soon is
   * advisable, e.g., in response to a pull bit.
   */
  
  command void triggerRouteUpdate();

  /**
   * This informs the routing engine that sending a beacon as soon
   * as possible is advisable, e.g., due to queue overflow or
   * a detected loop.
   */
  command void triggerImmediateRouteUpdate();

  /** 
   * Tell the routing engine it might want to recompute its routes.
   */
  command void recomputeRoutes();

  /**
   * Informs the routing engine that a neighbor is congested
   */
  command void setNeighborCongested(am_addr_t n, bool congested);

  /**
   *  Returns the currently known state about a neighbor's congestion state
   */
  command bool isNeighborCongested(am_addr_t n);

  command uint8_t numNeighbors();
  command uint16_t getNeighborLinkQuality(uint8_t n);
  command uint16_t getNeighborRouteQuality(uint8_t n);
  command am_addr_t getNeighborAddr(uint8_t n);
}
