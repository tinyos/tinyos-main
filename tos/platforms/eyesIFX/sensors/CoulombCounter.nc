/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Interface to control the coulomb counter circuit 
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de
 */

interface CoulombCounter {

    /** are we currently measureing the power consumption? */
    async command bool isMeasureing();
    
    /**
     *  Start a measurement after delay seconds for duration seconds delay
     *  seconds should be larger than 600 -- this allows to recover from a
     *  buggy image. The delay must be smaller than 24 days, whereas duration
     *  is full range 32bit in seconds. If the circuit is already measureing,
     *  this command will only set the duration timer. Some platforms will
     *  re-boot every time we fiddle with the power supply -- this trick
     *  allows us to "continue" measureing.
     */
    command error_t start(uint32_t delay, uint32_t duration);

    /** Stop a measurement, returns FAIL if there is no ongoing measurement */
    command error_t stop();

    /** notification: a fixed portion of energy has been consumed */
    async event void portionConsumed();

    /** notification that the measurement will be soon over */
    event void soonOver();
}
