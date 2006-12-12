/* $Id: BasicRouting.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
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

/** BasicRouting is to be implemented by all routing engines.
 *  @author Rodrigo Fonseca
 *  @date   $Date: 2006-12-12 18:23:29 $
 */
interface BasicRouting {
    /** Get a set of neighbors that make progress towards the destination.
     * @param nextHops: pointer to an array where to store the next hops found.
     *                  This array is allocated at the caller. If the message
     *                  is to be received by the local node, nextHops will 
     *                  contain exactly one entry, TOS_LOCAL_ADDRESS.
     * @param n : the maximum number of entries to return. Upon return, n
     *            has the number of entries actually returned. If the message
     *            is to be received locally, n will be set to 1.
     * @return : if the result is FAIL, n cannot be used.
     */
    command error_t getNextHops(am_addr_t* nextHops, uint8_t* n);
}

