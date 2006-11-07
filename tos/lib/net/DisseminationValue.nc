// $Id: DisseminationValue.nc,v 1.3 2006-11-07 19:31:18 scipio Exp $
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
 * Read a network shared (disseminated) variable and be notified
 * of updates.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 *
 * @date   Jan 7 2006
 */ 


interface DisseminationValue<t> {

  /**
   * Obtain a pointer to the variable. The provider of this
   * interface only will change the memory the pointer references
   * in tasks. Therefore the memory region does not change during
   * the execution of any other task. A user of this interface
   * must not in any circumstance write to this memory location.
   *
   * @return A const pointer to the variable.
   */
  command const t* get();

  /**
   * Signalled whenever variable may have changed.
   */
  event void changed();
}



