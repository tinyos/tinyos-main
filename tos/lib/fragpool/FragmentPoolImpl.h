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

#ifndef _FRAGMENT_POOL_IMPL_H_
#define _FRAGMENT_POOL_IMPL_H_

/** The code used for unique identifiers for fragment pool */
#define UQ_FRAGMENT_POOL "Unique.FragmentPool"

/** Type used for a fragment pool identifier.
 *
 * @note The test and validation infrastructure assumes this can take
 * negative values, so don't make it unsigned. */
typedef int fragment_pool_id_t;

/** Structure used to represent a signal fragment of a pool.  The
 * implementation maintains an array of these.  The following
 * invariants hold:
 *
 * + the start address of the pool is the start address of the first
 *   fragment
 *
 * + the sum of the absolute values of the fragment lengths equals the
 *   size of the pool
 *
 * + if the length of fragment i is zero, the length of all following
 *   fragments is zero
 *
 * + if the length of a fragment i is positive, the length of fragment
 *   i+1 is non-positive (adjacent free fragments are merged)
 */
typedef struct FragmentPoolSlot_t {
    /** Pointer to the start of the fragment.  Undefined if the slot
     * is not in use. */
    uint8_t* start;
    
    /** Length of the fragment.  If negative, the fragment is in use.
     * If zero, the slot is not in use.  If positive, the fragment is
     * available. */
    int length;
} FragmentPoolSlot_t;

#endif /* _FRAGMENT_POOL_IMPL_H_ */
