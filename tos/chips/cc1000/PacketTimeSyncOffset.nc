/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Brano Kusy
 *
 * Interface for one hop time synchronization. Allows to modify timesync
 * messages in the MAC layer with elapsed time of an event (ETA timesync
 * primitive). Interface also provides a command to determine offset within
 * a CC1000 packet, where the timesync ETA value is stored. word 'timestamping'
 * used in describing commands does not refer to metadata.timestamp value,
 * rather it refers to the timesync ETA timestamp which is part of data
 * payload and is transmitted over the air.
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

