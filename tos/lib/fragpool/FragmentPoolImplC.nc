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

/** Configuration that links together all the pools with the pool
 * management implementation.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration FragmentPoolImplC {
  provides {
    interface FragmentPool[fragment_pool_id_t];
#if TEST_FRAGMENT_POOL
    interface FragmentPoolTest;
#endif /* TEST_FRAGMENT_POOL */
  }
  uses {
    interface FragmentPoolStorage[fragment_pool_id_t];
  }
} implementation {
  enum {
    NUM_POOLS = uniqueCount(UQ_FRAGMENT_POOL)
  };

  components new FragmentPoolImplP(NUM_POOLS);
  FragmentPool = FragmentPoolImplP;
  FragmentPoolStorage = FragmentPoolImplP;
#if TEST_FRAGMENT_POOL
  FragmentPoolTest = FragmentPoolImplP;
#endif /* TEST_FRAGMENT_POOL */

  components MainC;
  MainC.SoftwareInit -> FragmentPoolImplP;
}

