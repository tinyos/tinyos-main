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

/** Support for a memory pool that fragments a large block into
 * arbitrarily sized smaller blocks based on need.
 *
 * The use case is buffer management for arbitrarily-sized messages,
 * such as HDLC frames received.  A client requests a block of memory,
 * fills part of it, then returns the remainder to the pool.  It may
 * then request a new block, while the newly received message is
 * processed.  Ultimately, the fragment is released back to the pool.
 * The largest available fragment is returned for each request.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface FragmentPool {
  /** Size of the pool, in bytes */
  async command unsigned int poolSize ();

  /** Number of slots for the pool
   *
   * This imposes an upper limit on the number of fragments allowed. */
  async command unsigned int slotCount ();

  /** Get the longest available fragment in the pool.
   *
   * @note No error checking is done on the pointers passed to this
   * method.  You must provide addresses for both the start and the
   * end fragment pointer.
   *
   * @param start Pointer to where the start of the fragment should be
   * written.  The address will be 16-bit aligned.  The stored value
   * is valid only when this function returns SUCCESS.
   *
   * @param end Pointer to where the end of the fragment should be
   * written.  This is the offset at which writing is no longer
   * permitted.  The stored value is valid only when this function
   * returns SUCCESS.
   *
   * @param minimum_size Minimum size, in bytes, that is useful to
   * the caller.  If the largest available fragment is not at least
   * this size, returns ENOMEM.
   *
   * @return SUCCESS if a fragment is available.  ENOMEM if no
   * fragments are available.  start and end are updated only if this
   * returns SUCCESS. */
  async command error_t request (uint8_t** start,
                                 uint8_t** end,
                                 unsigned int minimum_size);

  /** Release part of a previously allocated fragment.
   *
   * Note that a lack of available slots may prevent the fragment from
   * being split, so there is no guarantee that the remainder of the
   * fragment is available for re-use.  If it is, available() will be
   * signaled.  If it is not, the entire fragment remains allocated
   * until it is released.
   *
   * @param start Pointer to the fragment start.  Must be a value
   * previously returned by request but which has not been released or
   * frozen.
   *
   * @param end Pointer to the first byte of the released portion of
   * the fragment.
   *
   * @return SUCCESS in absence of an error, whether or not the
   * remainder of the fragment could be made available.  EINVAL if the
   * provided start does not correspond to a fragment, or if the end
   * is outside the fragment.
   */
  async command error_t freeze (const uint8_t* start,
                                const uint8_t* end);

  /** Release the fragment at the given address.
   *
   * @param start The address returned as start from a previous
   * request that has not been released.
   *
   * @return SUCCESS if the fragment was freed.  EINVAL if the start
   * address does not correspond to a fragment.  EALREADY if the
   * fragment had already been released. */
  async command error_t release (const uint8_t* start);

  /** Notification that a new fragment is available.
   *
   * Clients that require a minimum buffer length in order to function
   * may link to this event to be notified when a candidate is
   * created.
   *
   * @param length The number of bytes in the newly released
   * fragment. */
  async event void available (unsigned int length);
}
