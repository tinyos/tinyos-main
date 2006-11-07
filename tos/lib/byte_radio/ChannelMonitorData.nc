/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 */

/**
 * This interface is used by byte radio CCA components based on RSSI 
 * valid detection with a floating threshold.
 *
 * It provides commands and events to read the Signal to Noise Ratio 
 * (SNR) and noisefloor of the radio channel.
 *
 * @see ChannelMonitor
 * @see ChannelMonitorControl 
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Andreas Koepke (koepke@tkn.tu-berlin.de)
 */
interface ChannelMonitorData
{
    /** 
     * Sets the gradient for the conversion of mV and dB. 
     *
     *  @param grad This is calculated as grad = mV/dB
     */
    async command void setGradient(int16_t grad);
    
    /**
     * Returns the currently used gradient to convert between
     * dB and mV.
     *
     * @return The currently used gradient.
     */ 
    async command int16_t getGradient();

    /** 
     * Starts the SNR measurement 
     * 
     * @returns SUCCESS on success
     *          FAIL otherwise.
     */
    async command error_t getSnr();
    
    /**
     * Returns the SNR value in dB.
     *
     * @param snr The SNR value in dB.
    */
    async event void getSnrDone(int16_t snr);

    /**
     * try to be lucky: read anything stored as the rssi and
     * make a crude and fast conversion to an snr value
     */
    async command uint16_t readSnr();

    /** 
     * Get the noisefloor in mV.
     *
     * @return The noisefloor in mV.
     */
    async command uint16_t getNoiseFloor();
}
