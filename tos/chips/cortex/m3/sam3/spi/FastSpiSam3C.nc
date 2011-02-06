/*
 * Copyright (c) 2011 University of Utah
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Emulate fast spi with SpiByte
 */
generic module FastSpiSam3C(char resourceName[])
{
    provides
    {
        interface FastSpiByte[uint8_t];
    }
    uses
    {
        interface SpiByte[uint8_t];
    }
}

implementation
{
    enum 
    {
        NUM_CLIENTS = uniqueCount(resourceName)
    };

    volatile uint8_t lastRead[NUM_CLIENTS];

    /**
     * Starts a split-phase SPI data transfer with the given data.
     * A splitRead/splitReadWrite command must follow this command even 
     * if the result is unimportant.
     */
    async command void FastSpiByte.splitWrite[uint8_t id](uint8_t data){
        atomic lastRead[id] = call SpiByte.write[id](data);
    }

    /**
     * Finishes the split-phase SPI data transfer by waiting till 
     * the write command comletes and returning the received data.
     */
    async command uint8_t FastSpiByte.splitRead[uint8_t id](){
        atomic return lastRead[id];
    }

    /**
     * This command first reads the SPI register and then writes
     * there the new data, then returns. 
     */
    async command uint8_t FastSpiByte.splitReadWrite[uint8_t id](uint8_t data){
        uint8_t tmp;
        atomic {
            tmp = lastRead[id];
            lastRead[id] = call SpiByte.write[id](data);
        }
        return tmp;
    }

    /**
     * This is the standard SpiByte.write command but a little
     * faster as we should not need to adjust the power state there.
     * (To be consistent, this command could have be named splitWriteRead).
     */
    async command uint8_t FastSpiByte.write[uint8_t id](uint8_t data){
        return call SpiByte.write[id](data);
    }
}

