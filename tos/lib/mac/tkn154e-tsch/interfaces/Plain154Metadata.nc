/* 
 * Copyright (c) 2014, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * The Plain154Metadata interface allows to access metadata of a IEEE 802.15.4
 * frame.
 */

#include <plain154_message_structs.h>
#include <message.h>

interface Plain154Metadata
{

 /**
   * Returns a pointer to the Plain154-specific metadata section of a message_t
   *
   * @param frame     the frame
   * @return          a pointer to the frame's metadata
   */
  async command plain154_metadata_t* getMetadata(message_t* frame);

  /**
    * Returns the length of the message_t metadata portion of the frame (in byte).
    *
    * @param  frame   the frame 
    * @return         the length of the frame's payload (in byte)
    */
// TODO necessary? ->  async command uint8_t getMetadataLength(message_t* frame);

 /** 
  * Returns the time a frame was received or transmitted.
  * TODO exact time of the time stamp? begining and/or and of frame?
  * Time is expressed as ticks of the alarm used by the Plain154Phy implementation.
  * If <tt>isTimestampValid()</tt> returns FALSE then the timestamp is 
  * not valid and must be ignored.
  *
  * @param meta      the metadata of the frame 
  * @return          timestamp of the frame
  */
  async command uint32_t getTimestamp(plain154_metadata_t* meta);

 /**
  * Tells whether the timestamp is valid.
  *
  * @param meta      the metadata of the frame 
  * @return          TRUE if timestamp is valid, FALSE otherwise.
  */
  async command bool isTimestampValid(plain154_metadata_t* meta);
}
