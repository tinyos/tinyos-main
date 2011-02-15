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

#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface FragmentPool;
    interface FragmentPoolStorage;
    interface FragmentPoolTest;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>
  
#ifndef MAX_SLOTS
#define MAX_SLOTS (20)
#endif /* MAX_SLOTS */

  /** Length of the fragment from the most recent
   * FragmentPool.available() event.  Normally set to -1 to indicate
   * no fragments have been released. */
  int fragmentLength_;

  uint8_t* fragments_[MAX_SLOTS];
  unsigned int fragmentLengths_[MAX_SLOTS];

  async event void FragmentPool.available (unsigned int length)
  {
    fragmentLength_ = length;
  }

  int verifyPoolIntegrity (fragment_pool_id_t pid,
                            const char* tag)

  {
    FragmentPoolSlot_t* slots = call FragmentPoolTest.slots(pid);
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    uint8_t* pool = call FragmentPoolTest.pool(pid);
    unsigned int pool_size = call FragmentPoolTest.poolSize(pid);
    uint8_t* pp = pool;
    unsigned int size = 0;
    int sid = 0;
    int used_fragments = 0;

    printf("Verifying integrity of pool %d for %s\r\n", pid, tag);
    while (sid < slot_count) {
      FragmentPoolSlot_t* sp = slots + sid;

      //printf(" SLOT[%d] : %p %d\r\n", sid, sp->start, sp->length);

      /* Stop on unused slot */
      if (0 == sp->length) {
        break;
      }

      /* Fragment should start at proper address */
      ASSERT_EQUAL_PTR(pp, sp->start);

      /* Adjust next fragment address and total length */
      if (0 < sp->length) {
        /* Fragment is available */
        pp += sp->length;
        size += sp->length;
        if (0 < sid) {
          /* Previous fragment must be in use */
          ASSERT_TRUE(0 > slots[sid-1].length);
        }
        if ((sid+1) < slot_count) {
          /* Next slot must not be available */
          ASSERT_TRUE(0 >= slots[sid+1].length);
        }
      } else { //  (0 > sp->length)
        /* Fragment is in use */
        ++used_fragments;
        pp -= sp->length;
        size -= sp->length;
      }
      ++sid;
    }

    /* Entire pool must be accounted for in fragments */
    ASSERT_EQUAL(pool_size, size);

    /* Remainder of pool slots must be marked unused */
    while (sid < slot_count) {
      FragmentPoolSlot_t* sp = slots + sid;

      //printf(" SLOT[%d] : UNUSED %p %d\r\n", sid, sp->start, sp->length);
      ASSERT_EQUAL(0, sp->length);
      // ASSERT_EQUAL_PTR(0, sp->start);
      ++sid;
    }

    printf("done Verifying integrity of pool %d for %s; %d fragments in use\r\n", pid, tag, used_fragments);
    /* Return the number of fragments that were in use */
    return used_fragments;
  }

  void verifyPoolAvailable (fragment_pool_id_t pid,
                            const char* tag)
  {
    int n;
    printf("Verifying pool %d is completely available at %s\r\n", pid, tag);
    n = verifyPoolIntegrity(pid, tag);
    ASSERT_EQUAL(0, n);
    printf("done Verifying pool %d is completely available at %s\r\n", pid, tag);
  }

  void testPoolCount ()
  {
    ASSERT_EQUAL(1, call FragmentPoolTest.numPools());
    ASSERT_EQUAL(call FragmentPoolTest.slotCount(0), call FragmentPoolStorage.slotCount());
  }

  void testPoolInit ()
  {
    fragment_pool_id_t pid;

    pid = call FragmentPoolTest.numPools();
    while (0 <= --pid) {
      FragmentPoolSlot_t* slots = call FragmentPoolTest.slots(pid);
      int slot_count = call FragmentPoolTest.slotCount(pid);
      int sid = 0;
      ASSERT_EQUAL_PTR(slots[sid].start, call FragmentPoolStorage.pool());
      ASSERT_TRUE(0 == (1 & ((uint16_t)slots[sid].start)));
      ASSERT_EQUAL(slots[sid].length, call FragmentPoolStorage.poolSize());
      ASSERT_TRUE(0 == (1 & slots[sid].length));
      while (++sid < slot_count) {
        ASSERT_EQUAL_PTR(slots[sid].start, 0);
        ASSERT_EQUAL(slots[sid].length, 0);
      }
    }
    ASSERT_EQUAL(call FragmentPool.poolSize(), call FragmentPoolStorage.poolSize());
    ASSERT_EQUAL(call FragmentPool.slotCount(), call FragmentPoolStorage.slotCount());
  }

  void testPool0Params ()
  {
    printf("Pool id %d ; addr %p ; size %u ; slots %p ; slotCount %u\r\n",
           call FragmentPoolStorage.id(),
           call FragmentPoolStorage.pool(),
           call FragmentPoolStorage.poolSize(),
           call FragmentPoolStorage.slots(),
           call FragmentPoolStorage.slotCount());
    ASSERT_EQUAL(0, call FragmentPoolStorage.id());
    ASSERT_EQUAL(1024, call FragmentPoolStorage.poolSize());
    ASSERT_EQUAL(10, call FragmentPoolStorage.slotCount());
  }

  void testSingleAlloc ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    FragmentPoolSlot_t* slots = call FragmentPoolTest.slots(pid);
    //unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    uint8_t* pool = call FragmentPoolStorage.pool();
    unsigned int pool_size = call FragmentPoolStorage.poolSize();
    uint8_t* start;
    uint8_t* end;
    uint8_t* start2;
    uint8_t* end2;
    error_t rc;

    verifyPoolAvailable(pid, "testSingleAlloc.pre");

    rc = call FragmentPool.request(&start, &end, 0);

    /* Returned fragment equals entire pool */
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pool, start);
    ASSERT_EQUAL_PTR(start + pool_size, end);

    /* One slot, all in use */
    ASSERT_EQUAL_PTR(pool, slots[0].start);
    ASSERT_EQUAL(- pool_size, slots[0].length);
    ASSERT_EQUAL_PTR(0, slots[1].start);
    ASSERT_EQUAL(0, slots[1].length);

    /* Can't allocate another fragment */
    rc = call FragmentPool.request(&start2, &end2, 0);
    ASSERT_EQUAL(ENOMEM, rc);

    /* Release the fragment */
    fragmentLength_ = -1;
    rc = call FragmentPool.release(start);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(pool_size, fragmentLength_);

    /* One slot, available */
    ASSERT_EQUAL_PTR(pool, slots[0].start);
    ASSERT_EQUAL(pool_size, slots[0].length);
    ASSERT_EQUAL_PTR(0, slots[1].start);
    ASSERT_EQUAL(0, slots[1].length);

    verifyPoolAvailable(pid, "testSingleAlloc.post");
  }

  void testDoubleAlloc ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    FragmentPoolSlot_t* slots = call FragmentPoolTest.slots(pid);
    //unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    uint8_t* pool = call FragmentPoolStorage.pool();
    unsigned int pool_size = call FragmentPoolStorage.poolSize();
    uint8_t* start;
    uint8_t* end;
    unsigned int length;
    int rv;
    error_t rc;

    verifyPoolAvailable(pid, "testDoubleAlloc.init");
    rc = call FragmentPool.request(&start, &end, 0);

    /* Returned fragment equals entire pool */
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pool, start);
    ASSERT_EQUAL_PTR(start + pool_size, end);

    /* One slot, all in use */
    rv = verifyPoolIntegrity(pid, "testDoubleAlloc.post1");
    ASSERT_EQUAL(1, rv);

    /* Freeze half the pool */
    length = (end - start) / 2;
    fragmentLength_ = -1;
    rc = call FragmentPool.freeze(start, start + length);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(length, fragmentLength_);
    rv = verifyPoolIntegrity(pid, "testDoubleAlloc.postRel1");
    ASSERT_EQUAL(1, rv);
    ASSERT_EQUAL(pool_size - length, slots[1].length);
    ASSERT_EQUAL_PTR(pool + length, slots[1].start);

    /* Release the frozen half */
    fragmentLength_ = -1;
    rc = call FragmentPool.release(start);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(pool_size, fragmentLength_); // merged fragment is entire pool
    verifyPoolAvailable(pid, "testDoubleAlloc.done");
  }

  // Check that we cannot allocate more fragments than there are
  // slots, even if there is space available.
  void testOverPartition ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    unsigned int pool_size = call FragmentPoolStorage.poolSize();
    char tag[16];
    error_t rc;
    int length = 0;
    int sid;
    int n;
    uint8_t* start;
    uint8_t* end;
    
    ASSERT_TRUE(slot_count <= MAX_SLOTS);
    verifyPoolAvailable(pid, "testOverPartition.init");
    sid = 0;
    while (sid < slot_count) {
      rc = call FragmentPool.request(&start, &end, 0);
      ASSERT_EQUAL(SUCCESS, rc);
      sprintf(tag, "tOP %d req", sid);
      verifyPoolIntegrity(pid, tag);
      fragments_[sid] = start;

      ++sid;
      fragmentLength_ = -1;
      rc = call FragmentPool.freeze(start, start + 2*sid);
      ASSERT_EQUAL(SUCCESS, rc);
      if (sid < slot_count) {
        length += 2*sid;
        ASSERT_EQUAL(fragmentLength_, pool_size - length);
      } else {
        // No slots to partition last fragment
        ASSERT_EQUAL(fragmentLength_, -1);
      }

      sprintf(tag, "tOP %d frz", sid);
      n = verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(sid, n);
    }
    rc = call FragmentPool.request(&start, &end, 0);
    ASSERT_EQUAL(ENOMEM, rc);
    verifyPoolIntegrity(pid, "tOP.denied");
    
    while (0 <= --sid) {
      fragmentLength_ = -1;
      rc = call FragmentPool.release(fragments_[sid]);
      sprintf(tag, "tOP %d rel", sid);
      verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(fragmentLength_, pool_size - length);
      length -= 2*sid;
    }
    verifyPoolAvailable(pid, "testOverPartition.done");
  }

  int partitionPool (uint8_t** fragments,
                     fragment_pool_id_t pid,
                     int num_fragments)
  {
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    unsigned int pool_size = call FragmentPoolStorage.poolSize();
    uint8_t* start = 0;
    uint8_t* end;
    int sid;
    int per_fragment_length;
    error_t rc;
    int n;

    if (num_fragments > slot_count) {
      num_fragments = slot_count;
    }
    per_fragment_length = pool_size / num_fragments;

    for (sid = 0; sid < num_fragments; ++sid) {
      if (0 < sid) {
        rc = call FragmentPool.freeze(start, start + per_fragment_length);
        ASSERT_EQUAL(SUCCESS, rc);
        fragmentLengths_[sid-1] = per_fragment_length;
      }
      rc = call FragmentPool.request(&start, &end, 0);
      ASSERT_EQUAL(SUCCESS, rc);
      fragments_[sid] = start;
    }
    fragmentLengths_[sid-1] = pool_size - (num_fragments - 1) * per_fragment_length;
    n = verifyPoolIntegrity(pid, "partitionPool");
    ASSERT_EQUAL(num_fragments, n);

    return num_fragments;
  }

  void testFreezeMisuse ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    uint8_t* pool = call FragmentPoolStorage.pool();
    unsigned int pool_size = call FragmentPoolStorage.poolSize();
    int length;
    uint8_t* start;
    uint8_t* end;
    error_t rc;
    
    // pass invalid start pointer
    verifyPoolAvailable(pid, "testFreezeMisuse.init");
    rc = call FragmentPool.freeze(pool, pool + pool_size);
    ASSERT_EQUAL(EINVAL, rc);
    rc = call FragmentPool.freeze(pool + 4, pool + 8);
    ASSERT_EQUAL(EINVAL, rc);

    rc = call FragmentPool.request(&start, &end, 0);
    ASSERT_EQUAL(SUCCESS, rc);
    length = 1 + pool_size / 4;

    // end not in fragment
    rc = call FragmentPool.freeze(start, start - 4);
    ASSERT_EQUAL(EINVAL, rc);
    rc = call FragmentPool.freeze(start, end + 4);
    ASSERT_EQUAL(EINVAL, rc);

    // end equals fragment end
    rc = call FragmentPool.freeze(start, end);
    ASSERT_EQUAL(SUCCESS, rc);

    // end equals start
    rc = call FragmentPool.freeze(start, start);
    ASSERT_EQUAL(SUCCESS, rc);
    verifyPoolAvailable(pid, "testFreezeMisuse.freezeStart");
  }

  // test full and partial slot usage

  void testForwardReleaseFull ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    char tag[16];
    int sid;
    error_t rc;
    int n;

    ASSERT_EQUAL(slot_count, num_fragments);
    for (sid = 0; sid < num_fragments; ++sid) {
      sprintf(tag, "tFRF.%d", sid);
      n = verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(num_fragments - sid, n);
      rc = call FragmentPool.release(fragments_[sid]);
      ASSERT_EQUAL(SUCCESS, rc);
    }
    verifyPoolAvailable(pid, "tFRF.done");
  }

  void testBackwardReleaseFull ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    char tag[16];
    int rsid;
    int sid;
    error_t rc;
    int n;

    ASSERT_EQUAL(slot_count, num_fragments);
    for (rsid = 0; rsid < num_fragments; ++rsid) {
      sid = num_fragments - rsid - 1;
      sprintf(tag, "tBRF.%d", rsid);
      
      n = verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(num_fragments - rsid, n);
      rc = call FragmentPool.release(fragments_[sid]);
      ASSERT_EQUAL(SUCCESS, rc);
    }
    verifyPoolAvailable(pid, "tFRF.done");
  }

  void testMiddleRelease ()
  { 
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    char tag[16];
    int nfreed;
    int sid;
    error_t rc;
    int n;

    ASSERT_EQUAL(slot_count, num_fragments);
    nfreed = 0;

    // Release the odd-numbered fragments
    nfreed = 0;
    for (sid = 1; sid < num_fragments; sid += 2) {
      sprintf(tag, "tMR.%d", sid);
      rc = call FragmentPool.release(fragments_[sid]);
      fragments_[sid] = 0;
      ++nfreed;
      n = verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(num_fragments - nfreed, n);
    }
    n = verifyPoolIntegrity(pid, "tMR.evenRel");
    ASSERT_EQUAL(slot_count / 2, n);

    // Release fragment 2.  This merges with 1 and 3 already released.
    fragmentLength_ = -1;
    rc = call FragmentPool.release(fragments_[2]);
    ASSERT_EQUAL(SUCCESS, rc);
    fragments_[2] = 0;
    ++nfreed;
    ASSERT_EQUAL(fragmentLength_, fragmentLengths_[1] + fragmentLengths_[2] + fragmentLengths_[3]);
    n = verifyPoolIntegrity(pid, "tMR.2");
    ASSERT_EQUAL(num_fragments - nfreed, n);

    // Release the remaining fragments
    for (sid = 0; sid < num_fragments; ++sid) {
      if (0 == fragments_[sid]) {
        continue;
      }
      sprintf(tag, "tMR.%d", sid);
      rc = call FragmentPool.release(fragments_[sid]);
      ASSERT_EQUAL(SUCCESS, rc);
      ++nfreed;
      n = verifyPoolIntegrity(pid, tag);
      ASSERT_EQUAL(num_fragments - nfreed, n);
    }
    verifyPoolAvailable(pid, "tFRF.done");
  }

  void testAlignment ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    FragmentPoolSlot_t* slots = call FragmentPoolTest.slots(pid);
    error_t rc;
    uint8_t* start;
    uint8_t* end;

    rc = call FragmentPool.request(&start, &end, 0);
    ASSERT_TRUE(0 == (1 & ((uint16_t)start)));
    ASSERT_TRUE(0 == (1 & ((uint16_t)end)));
    rc = call FragmentPool.freeze(start, start + 3);
    ASSERT_EQUAL_PTR(start, slots[0].start);
    ASSERT_EQUAL(-4, slots[0].length);
    ASSERT_EQUAL_PTR(start+4, slots[1].start);

    rc = call FragmentPool.release(start);
  }

  void testMiddleFreeze ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    int rsid;
    error_t rc;

    ASSERT_EQUAL(slot_count, num_fragments);
    verifyPoolIntegrity(pid, "mf1");
    /* Release slot 2 */
    rc = call FragmentPool.release(fragments_[2]);
    fragments_[2] = 0;
    ASSERT_EQUAL(SUCCESS, rc);
    /* Freeze slot 1 */
    rc = call FragmentPool.freeze(fragments_[1], fragments_[1] + 5);
    ASSERT_EQUAL(SUCCESS, rc);
    verifyPoolIntegrity(pid, "mf2");
    for (rsid = 0; rsid < num_fragments; ++rsid) {
      if (fragments_[rsid]) {
        rc = call FragmentPool.release(fragments_[rsid]);
      }
    }
    verifyPoolAvailable(pid, "mf3");
  }

  void testMinimumSize ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    uint8_t* start;
    uint8_t* end;
    int frag_size;
    int rsid;
    error_t rc;

    ASSERT_EQUAL(slot_count, num_fragments);
    verifyPoolIntegrity(pid, "mf1");

    /* Release slot 2 */
    fragmentLength_ = -1;
    rc = call FragmentPool.release(fragments_[2]);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_TRUE(0 < fragmentLength_);
    frag_size = fragmentLength_ + 3;

    rc = call FragmentPool.request(&start, &end, frag_size);
    ASSERT_EQUAL(ENOMEM, rc);

    rc = call FragmentPool.release(fragments_[3]);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_TRUE(frag_size < fragmentLength_);

    rc = call FragmentPool.request(&start, &end, frag_size);
    ASSERT_EQUAL(SUCCESS, rc);
    rc = call FragmentPool.release(start);
    ASSERT_EQUAL(SUCCESS, rc);

    verifyPoolIntegrity(pid, "mf2");
    for (rsid = 0; rsid < num_fragments; ++rsid) {
      if (fragments_[rsid]) {
        rc = call FragmentPool.release(fragments_[rsid]);
      }
    }
    verifyPoolAvailable(pid, "mf3");
  }

  void testDoubleFreezeInternal ()
  {
    fragment_pool_id_t pid = call FragmentPoolStorage.id();
    unsigned int slot_count = call FragmentPoolTest.slotCount(pid);
    int num_fragments = partitionPool(fragments_, pid, slot_count);
    uint8_t* start;
    uint8_t* end;
    int frag_size;
    int rsid;
    error_t rc;

    /* Set up so the first N-1 slots are used, with the last one
     * empty */
    call FragmentPool.release(fragments_[slot_count-1]);
    call FragmentPool.release(fragments_[slot_count-2]);
    rc = call FragmentPool.request(&start, &end, 0);
    verifyPoolIntegrity(pid, "dfi1");

    /* Now reduce the size of the second-to-last active slot */
    call FragmentPool.freeze(fragments_[slot_count-3], fragments_[slot_count-3] + 5);
    verifyPoolIntegrity(pid, "dfi2");
    
    call FragmentPool.release(start);
    for (rsid = 0; rsid < num_fragments; ++rsid) {
      if (fragments_[rsid]) {
        rc = call FragmentPool.release(fragments_[rsid]);
      }
    }
    verifyPoolAvailable(pid, "dfiend");
  }

  event void Boot.booted () {
    printf("Starting test of FragmentPool\r\n");
    testPoolCount();
    testPoolInit();
    verifyPoolIntegrity(call FragmentPoolStorage.id(), "begin");
    testPool0Params();
    testSingleAlloc();
    testDoubleAlloc();
    testOverPartition();
    testFreezeMisuse();
    testForwardReleaseFull();
    testBackwardReleaseFull();
    testMiddleRelease();
    testAlignment();
    testMiddleFreeze();
    testMinimumSize();
    testDoubleFreezeInternal();
    verifyPoolIntegrity(call FragmentPoolStorage.id(), "end");
    ALL_TESTS_PASSED();
  }
}
