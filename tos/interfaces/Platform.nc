/*
 * Copyright (c) 2012, 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Platform: low level platform interface.
 *
 * The Platform interface is intended to present certain core h/w resources
 * in an easy to use fashion.
 *
 * Examples include:
 *
 *   o a low level us ticker that can be used for timeouts and instrumentation
 *     BusyWait doesn't work because you typically want to check for some
 *     terminating condition in the timing loop.
 *   o a low level jiffy ticker that is tied to an underlying long term
 *     ticker.  Typically this is a 32KiHz crystal based low power ticker.
 */

interface Platform {
  /*
   * platforms provide a low level usec timing element.
   * usecsRaw returns a raw value for this timing element.
   * This is used in low level time outs that are time based.
   *
   * Underlying h/w could be smaller than 32 bits.  Typically
   * if the recepient is smaller the return value will be truncated
   * to the size of the recepient, which is typically what you
   * want.
   *
   * "Size" returns number of bits implemented if you care.
   */
  async command uint32_t usecsRaw();
  async command uint32_t usecsRawSize();

  /*
   * platforms provide a longer term timing element.
   *
   * typically 32768 Hz (32 KiHz).  For lack of a better name
   * call it jiffies.  Note.   Existing code calls these ticks
   * jiffies already.
   *
   * Underlying h/w could be smaller than 32 bits.  "Size" returns
   * number of bits implemented if you care.
   */
  async command uint32_t jiffiesRaw();
  async command uint32_t jiffiesRawSize();
}
