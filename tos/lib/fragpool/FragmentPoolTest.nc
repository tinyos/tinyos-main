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

/** Back-end interface for white-box testing of implementation.
 *
 * Provides low-level access to the internals of FragmentPoolImplP so
 * that we can externally verify maintenance of the slot invariants
 * and retrieve other information that is not normally necessary in
 * client modules.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface FragmentPoolTest {
  /** The number of pools supported by the system */
  async command unsigned int numPools ();

  /** Access the slot data for a given pool.
   *
   * @param pid The pool id for which the first slot is requested */
  async command FragmentPoolSlot_t* slots (fragment_pool_id_t pid);

  /** Provide the number of slots in the given pool.
   *
   * @param pid The pool id for which the slot count is requested */
  async command unsigned int slotCount (fragment_pool_id_t pid);

  /** Access the buffer for a given pool.
   *
   * @param pid The pool id for which the buffer is requested */
  async command uint8_t* pool (fragment_pool_id_t pid);

  /** Provide the size of the given pool.
   *
   * @param pid The pool id for which the pool size is requested */
  async command unsigned int poolSize (fragment_pool_id_t pid);

}
