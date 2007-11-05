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

/**
 * There should be standard interfaces/commands for these
*/
interface HplRF230
{
	/**
	 * Calculates the crc. For some unknown reason the standard
	 * tinyos crcByte command swiches endianness.
	 */
	async command uint16_t crcByte(uint16_t crc, uint8_t data);

	/**
	 * Starts a split-phase SPI data transfer with the given data.
	 * A spiSplitRead command must follow this command even if the
	 * result is unimportant. The SpiByte interface should be 
	 * extended with this protocol.
	 */
	async command void spiSplitWrite(uint8_t data);

	/**
	 * Finishes the split-phase SPI data transfer by waiting till 
	 * the write command comletes and returning the received data.
	 */
	async command uint8_t spiSplitRead();

	/**
	 * This command first reads the SPI register and then writes
	 * there the new data, then returns
	 */
	async command uint8_t spiSplitReadWrite(uint8_t data);

	/**
	 * This is the standard SpiByte.write command but a little
	 * faster as we shuold not need to adjust the power state there.
	 */
	async command uint8_t spiWrite(uint8_t data);
}
