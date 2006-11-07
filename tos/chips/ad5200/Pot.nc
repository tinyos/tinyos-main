/*
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
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:30:43 $
 * ========================================================================
 */
 
/**
 * There is currently no TEP for describing this interface.<br><br>
 *
 * This interface is an attempt at describing the HIL abstraction for
 * potentiomter devices. Since there is currently no TEP describing the
 * abstractions for potentiometers, this interface will need to be updated
 * once one is created.
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Kevin Klues (klues@tkn.tu-berlin.de) -- modified for TinyOS-2.x
 */

interface Pot {

    /**
     * Set the potentiometer value.
     *
     * @param <b>setting</b> -- The new value of the potentiometer.
     * @return SUCCESS if the setting was successful<br>
     *         FAIL if the component has not been initialized or the desired
     *              setting is outside of the valid range. 
     */ 
  async command error_t set(uint8_t setting);

    /** 
     * Increment the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     * 
     * @return SUCCESS if the increment was successful.<br>
     *         FAIL if the component has not been initialized or if the
     *              potentiometer cannot be incremented further.
     */ 
  async command error_t increase();

    /** 
     * Decrement the potentiometer value by 1. This function proves to be
     * quite useful in active potentiometer control scenarios.
     *
     * @return SUCCESS if the decrement was successful.
     *         FAIL if the component has not been initialized or if the
     *              potentiometer cannot be decremented further.
     */ 
  async command error_t decrease();

    /**
     * Return the current setting of the potentiometer. 
     * @return An unsigned 8-bit value denoting the current setting of the
     *         potentiometer. 
     */
  async command uint8_t get();
}

