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

#include "FragmentPoolImpl.h"

/** Allocate a block of memory that can be partioned into individual
 * fragments.
 *
 * There is no limit on the duration that a fragment may be held, nor
 * any assumption on the order in which fragments are released.
 * Requests will fail only if the entire pool is in use.
 *
 * @param POOL_SIZE_B the number of bytes in the fragmentable buffer.
 * This must be a multiple of two, to preserve 16-bit alignment.  It's
 * not checked in the code, so don't be a goober and ignore this
 * requirement.
 *
 * @param FRAGMENT_COUNT the maximum number of fragments
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic configuration FragmentPoolC (unsigned int POOL_SIZE_B,
                                     unsigned int FRAGMENT_COUNT) {
  provides {
    interface FragmentPool;
#if TEST_FRAGMENT_POOL
    interface FragmentPoolStorage;
#endif /* TEST_FRAGMENT_POOL */
  }
} implementation {
  enum {
    POOL_ID = unique(UQ_FRAGMENT_POOL)
  };

  components new FragmentPoolStorageP(POOL_ID, POOL_SIZE_B, FRAGMENT_COUNT);
  
  components FragmentPoolImplC;
  FragmentPoolImplC.FragmentPoolStorage[POOL_ID] -> FragmentPoolStorageP;
  FragmentPool = FragmentPoolImplC.FragmentPool[POOL_ID];

#if TEST_FRAGMENT_POOL
  FragmentPoolStorage = FragmentPoolStorageP;
#endif /* TEST_FRAGMENT_POOL */
}

