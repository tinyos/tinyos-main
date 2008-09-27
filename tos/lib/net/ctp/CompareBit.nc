/* $Id: CompareBit.nc,v 1.3 2008-09-27 17:00:54 gnawali Exp $ */
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
 * should be inserted into the neighbor table if the
 * white bit on a link is set but there is no room for the link
 * on the link table. The return value is the "pin bit" - if true
 * insert into the neighbor table. In the reference implementation
 * the router will return true if the path through the source
 * will be better than a path through at least one current neighbor.
 @ author Omprakash Gnawali
 @ Created: September 16, 2006
 @date   $Date: 2008-09-27 17:00:54 $
 */

interface CompareBit {

  /* should the source of this message be inserted into the neighbor table? */
  /* expect to be called only for links with the white bit set */
   event bool shouldInsert(message_t * ONE msg, void* COUNT_NOK(len) payload, uint8_t len);
}
