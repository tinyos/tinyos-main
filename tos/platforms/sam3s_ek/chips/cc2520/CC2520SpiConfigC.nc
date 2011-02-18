/*
 * Copyright (c) 2011 University of Utah. 
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
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 *
 * @author Thomas Schmid
 */

module CC2520SpiConfigC 
{
    provides 
    {
        interface Init;
        interface ResourceConfigure;
    }
    uses {
        interface HplSam3SpiChipSelConfig;
        interface HplSam3SpiConfig;
    }
}
implementation {

    command error_t Init.init() {
        // configure clock 
        call HplSam3SpiChipSelConfig.setBaud(20);
        call HplSam3SpiChipSelConfig.setClockPolarity(0); // logic zero is inactive 
        call HplSam3SpiChipSelConfig.setClockPhase(1);    // out on rising, in on falling 
        call HplSam3SpiChipSelConfig.disableAutoCS();     // disable automatic rising of CS after each transfer 
        //call HplSam3SpiChipSelConfig.enableAutoCS(); 
 
        // if the CS line is not risen automatically after the last tx. The lastxfer bit has to be used. 
        call HplSam3SpiChipSelConfig.enableCSActive();    
        //call HplSam3SpiChipSelConfig.disableCSActive();  
 
        call HplSam3SpiChipSelConfig.setBitsPerTransfer(SPI_CSR_BITS_8); 
        call HplSam3SpiChipSelConfig.setTxDelay(0); 
        call HplSam3SpiChipSelConfig.setClkDelay(0); 
        return SUCCESS;
    }

    async command void ResourceConfigure.configure() {
        // Do stuff here
    }
    
    async command void ResourceConfigure.unconfigure() {
        // Do stuff here...
    }
}
