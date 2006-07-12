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
 * An LRU cache that stores integer values, where an insert operation
 * indicates "use".  Inserting an element not in the cache will replace 
 * the oldest, and inserting an element already in the cache will refresh 
 * its age.
 *
 * @author Rodrigo Fonseca
 * @author Philip Levis 
 */

generic module LruIntCacheP(typedef cache_key_t @integer(), uint8_t size) {
    provides {
        interface Init;
        interface Cache<cache_key_t>;
    }
}
implementation {
    cache_key_t cache[size];
    uint8_t first;
    uint8_t count;

    command error_t Init.init() {
        first = 0;
        count = 0;
        return SUCCESS;
    } 

    void printCache() {
#ifdef TOSSIM
        int i;
        dbg("Cache","Cache:");
        for (i = 0; i < count; i++) {
            dbg_clear("Cache", " %08x", cache[i]);
            if (i == first)
                dbg_clear("Cache","*");
        } 
        dbg_clear("Cache","\n");
#endif
    }

    /* if key is in cache returns the index (offset by first), otherwise returns count */
    uint8_t lookup(cache_key_t key) {
        uint8_t i;
	cache_key_t k;
        for (i = 0; i < count; i++) {
	   k = cache[(i + first) % size];
           if (k == key)
            break; 
        }
        return i;
    }

    /* remove the entry with index i (relative to first) */
    void remove(uint8_t i) {
        uint8_t j;
        if (i >= count) 
            return;
        if (i == 0) {
            //shift all by moving first
            first = (first + 1) % size;
        } else {
            //shift everyone down
            for (j = i; j < count; j++) {
                cache[(j + first) % size] = cache[(j + first + 1) % size];
            }
        }
        count--;
    }

    command void Cache.insert(cache_key_t key) {
        uint8_t i;
        if (count == size ) {
            //remove someone. If item not in 
            //cache, remove the first item.
            //otherwise remove the item temporarily for
            //reinsertion. This moves the item up in the
            //LRU stack.
            i = lookup(key);
            remove(i % count);
        }
        //now count < size
        cache[(first + count) % size] = key;
        count++;
    }

    command bool Cache.lookup(cache_key_t key) {
        return (lookup(key) < count);
    }

    command void Cache.flush() {
      call Init.init(); 
    }

}
