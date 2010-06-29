/*                                                                      
 *
 * Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 *
 */


/**
 * A generic interface to read from and write to the internal flash of
 * a microcontroller.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Prabal Dutta <prabal@cs.berkeley.edu> (Port to T2)
 */
interface InternalFlash {

  /**
   * Read <code>size</code> bytes starting from <code>addr</code> and
   * return them in <code>buf</code>.
   *
   * @param   addr A pointer to the starting address from which to read.
   * @param   'void* COUNT(size) buf'  A pointer to the buffer into which read bytes are
   *               placed.
   * @param   size The number of bytes to read.
   * @return  SUCCESS if the bytes were successfully read.
   *          FAIL if the call could not be completed.
   */
  command error_t read(void* addr, void* buf, uint16_t size);

  /**
   * Write <code>size</code> bytes from <code>buf</code> into internal
   * flash starting at <code>addr</code>.
   *
   * @param   addr A pointer to the starting address to which to write.
   * @param   'void* COUNT(size) buf'  A pointer to the buffer from which bytes are read.
   * @param   size The number of bytes to write.
   * @return  SUCCESS if the bytes were successfully written.
   *          FAIL if the call could not be completed.
   */
  command error_t write(void* addr, void* buf, uint16_t size);
}
