/* $Id: TreeRoutingInspect.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
/*
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
 */

/*
 *  @author Rodrigo Fonseca
 *  @date   $Date: 2006-12-12 18:23:29 $
 *  @see Net2-WG
 */


interface TreeRoutingInspect {
  /* Get the parent of the node in the tree.  The pointer is allocated
   * by the caller.  If the parent is invalid, return FAIL.  The
   * caller MUST NOT use the value in parent if the return is not
   * SUCCESS 
	 */
	command error_t getParent(am_addr_t* parent);

  /* Get the depth (hopcount) of the node in the tree.  The pointer is
   * allocated by the caller.  If the parent is invalid, return FAIL
   * (no info).  The caller MUST NOT use the value in parent if the
   * return is not SUCCESS 
	 */
	command error_t getHopcount(uint8_t* hopcount);

  /* Get the path quality metric for the current path to the root
   * through the current parent.  The pointer is allocated by the
   * caller.  If the parent is invalid, return FAIL (no info).  The
   * caller MUST NOT use the value in parent if the return is not
   * SUCCESS 
	 */
	command error_t getMetric(uint16_t* metric);

  /* This informs the routing engine to update its routing
   * information, possibly by sending a beacon */
  command void triggerRouteUpdate();
}
