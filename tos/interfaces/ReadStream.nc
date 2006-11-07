/*
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
 * The ReadStream interface is intended for buffered high data rate
 * reading, usually from sensor devices. The type of the values being
 * read is given as a template argument. 
 *
 * <p> To use this interface, allocate one or more buffers in your own
 * space. Then, call postBuffer to pass these buffers into the
 * device. Call read() to begin the sampling process. The buffers will
 * be filled in the order originally posted, and a bufferDone() event
 * will be signaled once each buffer has been filled with data. At any
 * time while the read() is running, you may post new buffers to be
 * filled. If the lower layer finishes signaling readDone() and then
 * finds that no more buffers have been posted, it will consider the
 * read to be finished, and signal readDone(). 
 *
 * <p>
 * See TEP114 - SIDs: Source and Sink Independent Drivers for details.
 * 
 * @param val_t the type of the object that will be returned
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:17 $
 */

interface ReadStream<val_t> {
  /**
   * Passes a buffer to the device, and indicates how many values
   * should be placed into the buffer. Make sure your count doesn't
   * overrun the buffer.
   *
   * @param buf a pointer to the buffer
   * @param count the number of values the buffer should hold
   *
   * @return SUCCESS if the post was successful
   */
  command error_t postBuffer(val_t* buf, uint16_t count);

  /**
   * Directs the device to start filling buffers by sampling with the
   * specified period. 
   * 
   * @param usPeriod the between-sample period in microseconds
   * 
   * @return SUCCESS if the reading process began
   */
  command error_t read(uint32_t usPeriod);

  /**
   * Signalled when a previously posted buffer has been filled by the
   * device. In the event of a read error, result will not equal
   * SUCCESS, and the buffer will be filled with zeroes.
   *
   * @param result SUCCESS if the buffer was filled without errors
   * @param buf a pointer to the buffer that has been filled
   * @param count the number of values actually read
   */
  event void bufferDone(error_t result, 
			 val_t* buf, uint16_t count);

  /**
   * Signalled when a buffer has been filled but no more buffers have
   * been posted. In the event of a read error, all previously posted
   * buffers will have their bufferDone() event signalled, and then
   * this event will be signalled with a non-SUCCESS argument.
   *
   * @param result SUCCESS if all buffers were filled without errors
   * @param usActualPeriod Actual sampling period used - may be different
   *   from period requested at read time. Undefined if result != SUCCESS.
   */
  event void readDone(error_t result, uint32_t usActualPeriod);
}    

