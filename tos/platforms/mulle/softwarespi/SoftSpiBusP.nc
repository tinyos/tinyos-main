/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
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
 * Mulle specific implementation of a software Spi bus.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module SoftSpiBusP()
{
    provides interface SoftSpiBus as Spi;

    uses interface GeneralIO as SCLK;
    uses interface GeneralIO as MISO;
    uses interface GeneralIO as MOSI;
}
implementation
{
    async command void Spi.init()
    {
        call SCLK.makeOutput();
        call MOSI.makeOutput();
        call MISO.makeInput();
        call SCLK.clr();
    }

    async command void Spi.off()
    {
        call SCLK.makeOutput();
        call MISO.makeOutput();
        call MOSI.makeOutput();
        call SCLK.clr();
        call MISO.clr();
        call MOSI.clr();
    }

    async command uint8_t Spi.readByte()
    {
        uint8_t i;
        uint8_t data = 0xde;

        atomic
        {
            for(i=0 ; i < 8; ++i)
            {
                call SCLK.clr();
                data = (data << 1) | (uint8_t) call MISO.get();
                call SCLK.set();
            }
        }
        return data;
    }

    async command void Spi.writeByte(uint8_t byte)
    {
        uint8_t  i = 8;
        atomic
        {
            for (i = 0; i < 8 ; ++i)
            {
                if (byte & 0x80)
                {
                    call MOSI.set();
                }
                else
                {
                    call MOSI.clr();
                }
                call SCLK.clr();
                call SCLK.set();
                byte <<= 1;
            }
        }
    }

    async command uint8_t Spi.write(uint8_t byte)
    {
        uint8_t data = 0;
        uint8_t mask = 0x80;

        atomic do
        {
            if( (byte & mask) != 0 )
                call MOSI.set();
            else
                call MOSI.clr();

            call SCLK.clr();
            if( call MISO.get() )
                data |= mask;
            call SCLK.set();
        } while( (mask >>= 1) != 0 );

        return data;
    }
}
