/*
 * Copyright (c) 2009 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

interface HplSam3GeneralIOPin
{
	async command void enablePioControl();
	/**
	 * Disables the PIO controller from driving the pin. The connected
	 * peripheral (if any) will do that.
	 */
	async command void disablePioControl();
	async command bool isEnabledPioControl();

	async command void enableMultiDrive();
	async command void disableMultiDrive();
	async command bool isEnabledMultiDrive();

	async command void enablePullUpResistor();
	async command void disablePullUpResistor();
	async command bool isEnabledPullUpResistor();

	async command void selectPeripheralA();
	async command void selectPeripheralB();
#ifdef CHIP_SAM3_HAS_PERIPHERAL_CD
	async command void selectPeripheralC();
	async command void selectPeripheralD();
#endif

	/**
	 * Returns TRUE if peripheral A is selected, returns FALSE if
	 * peripheral B is selected.
	 */
	async command bool isSelectedPeripheralA();

    // interrupt
    async command void enableInterrupt();
    async command void disableInterrupt();
    async command bool isEnabledInterrupt();

    // edge selection
    async command void enableEdgeDetection();
    async command bool isEnabledEdgeDetection();
    async command void fallingEdgeDetection();
    async command bool isFallingEdgeDetection();
    async command void risingEdgeDetection();

	/* TODO: input, and filter functions */
}
