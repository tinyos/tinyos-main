/*
 * "Copyright (c) 2006 The Regents of the University  of California.  
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

/**
 * A data item cache. The cache does not own the items it caches:
 * there is no allocation/deallocation policy, or notification of
 * eviction. Correspondingly, using references (pointers) as data
 * items can be difficult.
 * 
 * @author Rodrigo Fonseca
 * @author Philip Levis 
 */

interface Cache<t> {
    /**
     * Inserts an item in the cache, evicting if necessary.
     * An atomic lookup after insert should return true.
     *
     * @param item - the data item to insert.
     */
    command void insert(t item);

    /**
      * Return whether the data item is in the cache.
      *
      * @param item - the data item to query
      * @return Whether the item is in the cache.
      */ 
    command bool lookup(t item);
   
    /**
      * Flush the cache of all entries.
      *
      */
    command void flush();
}

