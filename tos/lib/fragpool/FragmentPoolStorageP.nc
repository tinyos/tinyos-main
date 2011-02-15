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

/** The module that reserves storage for the pool.
 *
 * @param POOL_SIZE_B the number of bytes in the fragmentable buffer
 * @param FRAGMENT_COUNT the maximum number of fragments
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic module FragmentPoolStorageP (fragment_pool_id_t POOL_ID,
                                     unsigned int POOL_SIZE_B,
                                     unsigned int FRAGMENT_COUNT) {
  provides interface FragmentPoolStorage;
} implementation {

  /** The pool buffer.  Aligned to 16-bits. */
  uint16_t pool[(1 + POOL_SIZE_B) / 2];
  /** Information on fragmentation of the buffer */
  FragmentPoolSlot_t slots[FRAGMENT_COUNT]; // = { { (uint8_t*)pool, sizeof(pool) } };

  async command fragment_pool_id_t FragmentPoolStorage.id () { return POOL_ID; }
  async command uint8_t* FragmentPoolStorage.pool () { return (uint8_t*)pool; }
  async command unsigned int FragmentPoolStorage.poolSize () { return sizeof(pool); }
  async command FragmentPoolSlot_t* FragmentPoolStorage.slots () { return slots; }
  async command unsigned int FragmentPoolStorage.slotCount () { return sizeof(slots) / sizeof(*slots); }
}
