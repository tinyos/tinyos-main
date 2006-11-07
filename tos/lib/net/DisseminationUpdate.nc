// $Id: DisseminationUpdate.nc,v 1.3 2006-11-07 19:31:18 scipio Exp $
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Update a network shared (disseminated) value. Updates are assured
 * to be eventually consistent across a connected network. If multiple
 * nodes update a value simultaneously, then nodes within the network
 * will see a series of one or more updates, the last update will
 * be the same for all nodes. Components that need to use the
 * variable should use the DisseminationValue interface.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 * @date   January 7 2006
 */ 



interface DisseminationUpdate<t> {
  /**
   * Update the variable to a new value. This changes the local copy
   * and begins to disseminate the new value throughout the network.
   * As other nodes may have also changed the variable, it is possible
   * that an update may not 'stick,' but will instead be overwritten by
   * a separate update.
   *
   * @param newVal A pointer to the new value. The memory pointed to
   * by newVal is copied out, so newVal can be reclaimed when
   * <tt>change</tt> returns.
   */
  command void change(t* newVal);
}
