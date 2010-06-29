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
 * - Neither the name of the copyright holder nor the names of
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
