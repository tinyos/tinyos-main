/* $Id: LinkEstimator.nc,v 1.3 2006-11-07 19:31:19 scipio Exp $ */
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

/** Provides an additive quality measure for a neighbor. The
 * provided quality increases when the true link quality increases.
 *  @author Rodrigo Fonseca
 *  @author Omprakash Gnawali
 *  @date   $Date: 2006-11-07 19:31:19 $
 */

/* Quality of a link is defined by the implementor of this interface.
 * It could be ETX, PRR, etc.
 */

interface LinkEstimator {
  
  /* get bi-directional link quality for link to the neighbor */
  command uint8_t getLinkQuality(uint16_t neighbor);

  /* get quality of the link from neighbor to this node */
  command uint8_t getReverseQuality(uint16_t neighbor);

  /* get quality of the link from this node to the neighbor */
  command uint8_t getForwardQuality(uint16_t neighbor);

  /* insert this neighbor into the neighbor table */
  command error_t insertNeighbor(am_addr_t neighbor);

  /* pin a neighbor so that it does not get evicted */
  command error_t pinNeighbor(am_addr_t neighbor);

  /* pin a neighbor so that it does not get evicted */
  command error_t unpinNeighbor(am_addr_t neighbor);

  /* called when an acknowledgement is received; sign of a successful
     data transmission; to update forward link quality */
  command error_t txAck(am_addr_t neighbor);

  /* called when an acknowledgement is not received; could be due to
     data pkt or acknowledgement loss; to update forward link quality */
  command error_t txNoAck(am_addr_t neighbor);

  /* called when the parent changes; clear state about data-driven link quality  */
  command error_t clearDLQ(am_addr_t neighbor);

  /* signal when this neighbor is evicted from the neighbor table */
  event void evicted(am_addr_t neighbor);
}


