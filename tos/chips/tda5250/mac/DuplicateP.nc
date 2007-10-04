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
/**
 * Helper component for MAC protocols to suppress duplicates
 * To do: turn it into a generic?
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

module DuplicateP {
  provides {
      interface Duplicate;
      interface Init;
  }
  uses {
      interface Timer<TMilli> as Timer;
#ifdef DUPLICATE_DEBUG
      interface SerialDebug;
#endif
  }
}
implementation {
    known_t knownTable[TABLE_ENTRIES];
    
#ifdef DUPLICATE_DEBUG
    void sdDebug(uint16_t p) {
        call SerialDebug.putPlace(p);
    }
    known_t dupOldest;
    unsigned last;
    task void dump() {
        sdDebug(3000 + last);
        sdDebug(dupOldest.src);
        sdDebug(dupOldest.seqno);
        sdDebug(dupOldest.age);
        sdDebug(4000);
        sdDebug(knownTable[last].src);
        sdDebug(knownTable[last].seqno);
        sdDebug(knownTable[last].age);
        sdDebug(5000);
    }
#else
    void sdDebug(uint16_t p) {};
#endif
    
    /** helper functions */
    task void ageMsgsTask() {
        unsigned i;
        for(i = 0; i < TABLE_ENTRIES; i++) {
            atomic {
                if(knownTable[i].age < MAX_AGE) ++knownTable[i].age;
            }
        }
    }
    
    unsigned findOldest() {
        unsigned i;
        unsigned oldIndex = 0;
        unsigned age = knownTable[oldIndex].age;
        for(i = 1; i < TABLE_ENTRIES; i++) {
            if(age < knownTable[i].age) {
                oldIndex = i;
                age = knownTable[i].age;
            }
        }
        return oldIndex;
    }

    /*** duplicate interface */
    async command bool Duplicate.isNew(am_addr_t src, uint8_t seqno) {
        bool rVal = TRUE;
        unsigned i;
        for(i=0; i < TABLE_ENTRIES; i++) {
            if((knownTable[i].age < MAX_AGE) &&
               (src == knownTable[i].src) &&
               (seqno == knownTable[i].seqno)) {
                knownTable[i].age = 0;
                rVal = FALSE;
                break;
            }
        }
        sdDebug(100 + rVal);
        sdDebug(200 + i);
        return rVal;
    }
    
    async command void Duplicate.remember(am_addr_t src, uint8_t seqno) {
        unsigned oldest = findOldest();
#ifdef DUPLICATE_DEBUG
        dupOldest = knownTable[oldest];
        last = oldest;
        post dump();
#endif
        knownTable[oldest].src = src;
        knownTable[oldest].seqno = seqno;
        knownTable[oldest].age = 0;
        post ageMsgsTask();
    }

    /** helper interfaces */
    event void Timer.fired() {
        post ageMsgsTask();
    }

    command error_t Init.init(){
        uint8_t i;
        for(i = 0; i < TABLE_ENTRIES; i++) {
            atomic {
                knownTable[i].age = MAX_AGE;
            }
        }
        call Timer.startPeriodic(AGE_INTERVALL);
        return SUCCESS;
    }
}

