/* -*- mode:c++; indent-tabs-mode:nil -*- 
 * Copyright (c) 2007, Technische Universitaet Berlin
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
 */

module LocalTimeP {
    provides {  
        interface LocalTime<T32khz> as LocalTime32kHz;
        interface WideLocalTime<T32khz> as WideLocalTime;
    }
    uses {
        interface Counter<T32khz,uint16_t> as Counter32khz16;
    }
}
implementation  {
    uint16_t counter2sec = 40000U;
    int32_t dayCounter = 0;
    bool increaseDay = FALSE;
    async command uint32_t LocalTime32kHz.get() {
        int64_t time;
        unsigned t;
        bool dirty1;
        bool dirty2;
        atomic {
            increaseDay = FALSE;
            do {
                dirty1 = call Counter32khz16.isOverflowPending();
                t = call Counter32khz16.get();
                dirty2 = call Counter32khz16.isOverflowPending();
            } while (dirty1 != dirty2);
            time = counter2sec;
            if(dirty1) {
                ++time;
                if(time == 0) {
                    increaseDay = TRUE;
                }
            }
            time = (time << 16) + t;
        }
        return time;
    }

    async command int64_t WideLocalTime.get() {
        int64_t time;
        uint32_t t;
        atomic {
            t = call LocalTime32kHz.get();
            time = dayCounter;
            if(increaseDay) time++;
            if(time < 0) time = 0;
            time <<= 32;
            time += t;
        }
        return time;
    }
    
    async event void Counter32khz16.overflow() {
        ++counter2sec;
        if(counter2sec == 0) ++dayCounter;
        if(dayCounter < 0) dayCounter = 0;
    }
}

