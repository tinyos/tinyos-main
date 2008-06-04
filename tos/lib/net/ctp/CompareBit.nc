/* $Id: CompareBit.nc,v 1.2 2008-06-04 04:30:41 regehr Exp $ */
/*
 * "Copyright (c) 2006 University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/** Link estimator asks the routing engine if this entry
 * should be inserted into the neighbor table given the
 * white bit. The return value is the "pin bit" - if true
 * insert into the neighbor table. In the reference implementation
 * the router will return true if the path through the source
 * will be better than a path through at least one current neighbor.
 @ author Omprakash Gnawali
 @ Created: September 16, 2006
 @date   $Date: 2008-06-04 04:30:41 $
 */

interface CompareBit {

  /* should the source of this message be inserted into the neighbor table? */
   event bool shouldInsert(message_t * ONE msg, void* COUNT_NOK(len) payload, uint8_t len, bool white_bit);
}
