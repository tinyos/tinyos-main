/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Module to implement management of all fragment pools.
 *
 * @param NUM_POOLS The total number of pools allocated throughout the
 * system.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic module FragmentPoolImplP (unsigned int NUM_POOLS) {
  provides {
    interface Init;
    interface FragmentPool[fragment_pool_id_t];
#if TEST_FRAGMENT_POOL
    interface FragmentPoolTest;
#endif /* TEST_FRAGMENT_POOL */
  }
  uses {
    interface FragmentPoolStorage[fragment_pool_id_t];
  }
} implementation {

  /** Information on a specific pool */
  typedef struct FragmentPool_t {
      /** Where the slot array for the pool got placed */
      FragmentPoolSlot_t* slots;
      /** The number of slots in the pool */
      unsigned int slot_count;
  } FragmentPool_t;

  /** Data for all pools.  The slots array contents of each structure
   * must be maintained atomically. */
  FragmentPool_t pools__[NUM_POOLS];

#if TEST_FRAGMENT_POOL
  async command unsigned int FragmentPoolTest.numPools () { return sizeof(pools__) / sizeof(*pools__); }
  async command FragmentPoolSlot_t* FragmentPoolTest.slots (fragment_pool_id_t pid) { return pools__[pid].slots; }
  async command unsigned int FragmentPoolTest.slotCount (fragment_pool_id_t pid) { return pools__[pid].slot_count; }
  async command uint8_t* FragmentPoolTest.pool (fragment_pool_id_t pid) { return call FragmentPoolStorage.pool[pid](); }
  async command unsigned int FragmentPoolTest.poolSize (fragment_pool_id_t pid) { return call FragmentPoolStorage.poolSize[pid](); }
#endif /* TEST_FRAGMENT_POOL */

  bool initialized__;
  void initialize__ () {
    if (! initialized__) {
      int pid;

      /* Extract the individual pool data.  Note that each pool can be a
       * different size, and have a different number of slots.  This
       * code relies on zero-init of pools__ to maintain the slot
       * invariants. */
      for (pid = 0; pid < NUM_POOLS; ++pid) {
        FragmentPool_t* pp = pools__ + pid;
        pp->slots = call FragmentPoolStorage.slots[pid]();
        pp->slot_count = call FragmentPoolStorage.slotCount[pid]();
        if (0 < pp->slot_count) {
          pp->slots[0].start = call FragmentPoolStorage.pool[pid]();
          pp->slots[0].length = call FragmentPoolStorage.poolSize[pid]();
        }
      }
      initialized__ = TRUE;
    }
  }
#define CHECK_INITIALIZED__() atomic do { if (! initialized__) { initialize__(); } } while (0)

  command error_t Init.init () {
    atomic initialize__();
    return SUCCESS;
  }

  default async command fragment_pool_id_t FragmentPoolStorage.id[ fragment_pool_id_t pid] () { return -1; }
  default async command uint8_t* FragmentPoolStorage.pool[ fragment_pool_id_t pid] () { return 0; }
  default async command unsigned int FragmentPoolStorage.poolSize[ fragment_pool_id_t pid] () { return 0; }
  default async command FragmentPoolSlot_t* FragmentPoolStorage.slots[ fragment_pool_id_t pid] () { return 0; }
  default async command unsigned int FragmentPoolStorage.slotCount[ fragment_pool_id_t pid] () { return 0; }

  default async event void FragmentPool.available[ fragment_pool_id_t pid] (unsigned int length) { }

  async command unsigned int FragmentPool.poolSize[ fragment_pool_id_t pid] () { return call FragmentPoolStorage.poolSize[pid](); }
  async command unsigned int FragmentPool.slotCount[ fragment_pool_id_t pid] () { return call FragmentPoolStorage.slotCount[pid](); }

#if DEBUG_FRAGMENT_POOL
  void validatePool__ (fragment_pool_id_t pid)
  {
    FragmentPoolSlot_t* sp = pools_[pid].slots;
    FragmentPoolSlot_t* spe = sp + pools_[pid].slot_count;
    unsigned int size = 0;
    while (sp < spe) {
      size += abs(sp->length);
      ++sp;
    }
    if (call FragmentPoolStorage.poolSize[pid]() != size) {
      DisplayCode_lock(15);
    }
  }
#else
#define validatePool__(_p) ((void)0)
#endif

  async command error_t FragmentPool.request[fragment_pool_id_t pid] (uint8_t** start,
                                                                      uint8_t** end,
                                                                      unsigned int minimum_size)
  {
    FragmentPoolSlot_t* sp;
    FragmentPoolSlot_t* spe;
    FragmentPoolSlot_t* bsp;
    unsigned int bsp_length;

    atomic {
      CHECK_INITIALIZED__();

      sp = pools__[pid].slots;
      spe = sp + pools__[pid].slot_count;

      /* Find the longest open fragment in the pool that's at least
       * the requested size. */
      bsp = 0;
      bsp_length = minimum_size;
      while (sp < spe) {
	if ((0 < sp->length) && (bsp_length <= sp->length)) {
	  bsp = sp;
	  bsp_length = sp->length;
	}
        ++sp;
      }

      /* If no satisfactory fragment is available, return failure. */
      if (! bsp) {
        return ENOMEM;
      }

      /* Store the return values and mark the fragment in use */
      *start = bsp->start;
      *end = bsp->start + bsp->length;
      bsp->length = - bsp->length;
      validatePool__(pid);
    } // end atomic
    return SUCCESS;
  }
  
#if DEBUG_FRAGMENT_POOL
  volatile const uint8_t* start__;
  volatile const uint8_t* end__;
  volatile FragmentPoolSlot_t slots__[8];
#endif

  async command error_t FragmentPool.freeze[fragment_pool_id_t pid] (const uint8_t* start,
                                                                     const uint8_t* end)
  {
    FragmentPoolSlot_t* sp;
    FragmentPoolSlot_t* spe;
    unsigned int free_length;
    bool need_release = FALSE;
    
    //CHECK_INITIALIZED__();
    sp = pools__[pid].slots;
    spe = sp + pools__[pid].slot_count;
    atomic {
      uint8_t* fep;

#if DEBUG_FRAGMENT_POOL
      start__ = start;
      end__ = end;
      memcpy(slots__, pools_[pid].slots, pools_[pid].slot_count * sizeof(*slots__));
#endif

      while ((sp < spe) && (start != sp->start)) {
        ++sp;
      }
      if (sp == spe) {
        return EINVAL;
      }
      /* Get a pointer to the end of the original fragment */
      fep = sp->start - sp->length;
      if ((end < sp->start) || (fep < end)) {
        // end not within fragment: error
        return EINVAL;
      }
      /* Determine how many bytes are potentially released.  If it's
       * an odd number, decrement it to ensure fragment sizes are
       * multiples of two. */
      free_length = fep - end;
      if (1 & free_length) {
        --free_length;
      }

      if (sp->start == end) {
        // Releasing whole thing; just use that implementation
        // (outside atomic block)
        need_release = TRUE;
        goto post_atomic;
      }

      if ((0 == free_length) || ((sp+1) == spe)) {
        // Entire fragment remains frozen; or, there're no slots to
        // merge to: short exit
        return SUCCESS;
      }

      if (0 < sp[1].length) {
        /* The following fragment is free, we can adjust its start to
         * merge it with the released portion without using any
         * additional slots. */
        sp->length += free_length;
        ++sp;
        sp->start -= free_length;
        sp->length += free_length;
      } else {
        if (0 > sp[1].length) {
          /* Next slot holds a frozen fragment.  We'll need to shift
           * it and everything that follows up one slot.  If there are
           * no unused slots at the end, we just leave this fragment
           * fully allocated. */
          if (0 != spe[-1].length) {
            // Last slot is used: no room to shift
            return SUCCESS;
          }
          /* Shift spe down to point to the first unused slot above
           * sp+1 (which we know is used) */
          while (((sp+2) < spe) && (0 == spe[-1].length)) {
            --spe;
          }
          memmove(sp+2, sp+1, (spe - (sp+1)) * sizeof(*sp));
        }
        sp->length += free_length;
        sp[1].start = sp->start - sp->length;
        ++sp;
        sp->length = free_length;
      }
      free_length = sp->length;
post_atomic:
      validatePool__(pid);
      /*FALLTHRU*/
    } /* atomic */
    if (need_release) {
      return call FragmentPool.release[pid](start);
    }
    signal FragmentPool.available[pid](free_length);
    return SUCCESS;
  }

  async command error_t FragmentPool.release[fragment_pool_id_t pid] (const uint8_t* start)
  {
    FragmentPoolSlot_t* sp;
    FragmentPoolSlot_t* spe;
    FragmentPoolSlot_t* bsp;
    FragmentPoolSlot_t* asp;
    unsigned int merged_length;

    //CHECK_INITIALIZED__();
    sp = pools__[pid].slots;
    spe = sp + pools__[pid].slot_count;
    atomic {
      /* Scan for the fragment at the given address. */
      while ((sp < spe) && (start != sp->start)) {
        ++sp;
      }

      /* Two ways to fail: we didn't find the fragment, or the fragment
       * isn't in use.  They're both catastrophic: one is a user
       * failure, the other may be either a user or an infrastructure
       * failure.  Give the user a chance to identify the problem.  */
      if (sp == spe) {
        return EINVAL;
      }
      if (0 <= sp->length) {
        return EALREADY;
      }

      /* Release the fragment */
      sp->length = -sp->length;

      /* See whether we can merge with the slot below and/or above
       * this one. */
      bsp = asp = sp;
      if ((pools__[pid].slots < bsp) && (0 < bsp[-1].length)) {
        --bsp;
      }
      if (((asp+1) < spe) && (0 < asp[1].length)) {
        ++asp;
      }

      /* bsp points to the slot holding the start of the merged
       * fragment.  asp points to the last slot that can be aggregated
       * into the merged fragment.  If they aren't the same, there are
       * dead slots we can re-use.  Shift the active slots above asp
       * down to above bsp, and reset the state of the rest. */
      sp = bsp;
      if (bsp < asp) {
        int num_freed_slots = asp - bsp;
        
        /* Aggregate the lengths from the intervening slots into the first
         * one. */
        asp = bsp;
        while (asp++ < (bsp + num_freed_slots)) {
          bsp->length += asp->length;
        }

        /* Keep copying until we've hit the upper bound or an unused
         * slot */
        while (asp < spe) {
          asp[-num_freed_slots] = *asp;
          if (0 == asp->length) {
            break;
          }
          ++asp;
        }

        /* Mark unused the slots we freed */
        bsp = asp - num_freed_slots;
        while (bsp < asp) {
          bsp->length = 0;
          ++bsp;
        }
      }
      merged_length = sp->length;
      validatePool__(pid);
    } // end atomic
    signal FragmentPool.available[pid](merged_length);
    return SUCCESS;
  }

#undef CHECK_INITIALIZED__

}
