/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
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
 * Author: Miklos Maroti, Brano Kusy
 *
 * Interface for one hop time synchronization. Allows to modify timesync
 * messages in the MAC layer with elapsed time of an event (ETA timesync
 * primitive). Interface also provides a command to determine offset within
 * a CC2420 packet, where the timesync ETA value is stored. word 'timestamping'
 * used in describing commands does not refer to metadata.timestamp value,
 *  rather it refers to the timesync ETA timestamp which is part of data
 *  payload and is transmitted over the air.
 */

interface PacketTimeSyncOffset
{
    /**
     * @param 'message_t *ONE msg' message to examine.
     *
     * Returns TRUE if the current message should be timestamped.
     */
    async command bool isSet(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to examine.
     *
     * Returns the offset of where the timesync timestamp is sotred in a
     * CC2420 packet
     */
    async command uint8_t get(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to modify.
     *
     *  Sets the current message to be timestamped in the MAC layer.
     */
    async command void set(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to modify.
     *
     * Cancels any pending requests to timestamp the message in MAC.
     */
    async command void cancel(message_t* msg);
}
