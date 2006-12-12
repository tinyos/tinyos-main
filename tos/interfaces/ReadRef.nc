/**
 * Copyright (c) 2005 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * The ReadRef interface is intended for split-phase low-rate or
 * high-latency reading of large values. The type of the value is
 * given as a template argument. When a value is too large to be
 * comfortably passed on the stack, the caller should allocate space
 * for the value and pass the pointer to read(). When the readDone()
 * comes back, the space will be filled with the new value.
 *
 * <p>
 * See TEP114 - SIDs: Source and Sink Independent Drivers for details.
 * 
 * @param val_t the type of the object that will be returned
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:15 $
 */

interface ReadRef<val_t> {
  /**
   * Initiates a read of the value.
   * 
   * @param val a pointer to space that will be filled by the value
   *
   * @return SUCCESS if a readDone() event will eventually come back.
   */
  command error_t read( val_t* val );
  
  /**
   * Signals the completion of the read(). The returned pointer will
   * be the same as the original pointer passed to read().
   *
   * @param result SUCCESS if the read() was successful
   * @param val a pointer to the value that has been read
   */
  event void readDone( error_t result, val_t* val );
}
