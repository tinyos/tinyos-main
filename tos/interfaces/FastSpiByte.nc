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
 * This is a natural extension of the SpiByte interface which allows fast 
 * data transfers comparable to the SpiStream interface. You may want to
 * use the following code sequence to write a buffer as fast as possible
 *
 *	call FastSpiByte.spiSplitWrite(data[0]); // start the first byte
 *	for(i = 1; i < length; ++i) {
 *	   // finish the previous one and write the next one
 *	  call FastSpiByte.spiSplitReadWrite(data[i]);
 *	}
 *	call FastSpiByte.spiSlitRead(); // finish the last byte
 *
 * You can also do some useful computation (like calculate a CRC) while the
 * hardware is sending the byte.
 */
interface FastSpiByte
{
	/**
	 * Starts a split-phase SPI data transfer with the given data.
	 * A splitRead/splitReadWrite command must follow this command even 
	 * if the result is unimportant.
	 */
	async command void splitWrite(uint8_t data);

	/**
	 * Finishes the split-phase SPI data transfer by waiting till 
	 * the write command comletes and returning the received data.
	 */
	async command uint8_t splitRead();

	/**
	 * This command first reads the SPI register and then writes
	 * there the new data, then returns. 
	 */
	async command uint8_t splitReadWrite(uint8_t data);

	/**
	 * This is the standard SpiByte.write command but a little
	 * faster as we should not need to adjust the power state there.
	 * (To be consistent, this command could have be named splitWriteRead).
	 */
	async command uint8_t write(uint8_t data);
}
