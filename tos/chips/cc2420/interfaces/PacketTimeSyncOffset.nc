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
 * Author: Miklos Maroti
 */

interface PacketTimeSyncOffset
{
    /**
     * @param 'message_t *ONE msg' message to examine.
     *
     * Returns TRUE if the value is set for this message.
     */
    async command bool isSet(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to examine.
     *
     * Returns the stored value of this field in the message. If the
     * value is not set, then the returned value is undefined.
     */
    async command uint8_t get(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to modify.
     *
     * Sets the isSet false to TRUE and the time stamp value to the
     * specified value.
     */
    async command void set(message_t* msg);

    /**
     * @param 'message_t *ONE msg' message to modify.
     *
     * Cancels any pending requests.
     */
    async command void cancel(message_t* msg);
}
