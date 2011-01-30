/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * Basic Clock Initialization.
 *
 * @author Thomas Schmid
 */

#include "sam3upmchardware.h"
#include "sam3usupchardware.h"
#include "sam3eefchardware.h"
#include "sam3wdtchardware.h"
#include "sam3matrixhardware.h"

extern void SetDefaultMaster(unsigned char enable);


module MoteClockP
{
    provides 
    {
        interface Init;
    }
    uses
    {
        interface HplSam3Clock;
        interface Leds;
    }
}

implementation
{

    command error_t Init.init(){
        // Set 2 WS for Embedded Flash Access
        EEFC0->fmr.bits.fws = 2;
        EEFC1->fmr.bits.fws = 2;

        // Disable Watchdog
        WDTC->mr.bits.wddis = 1;

        // Select external slow clock
        call HplSam3Clock.slckExternalOsc();
        //call HplSam3Clock.slckRCOsc();

        // Initialize main oscillator
        call HplSam3Clock.mckInit48();
        //call HplSam3Clock.mckInit12RC();

        // Enable clock for UART
        // FIXME: this should go into the UART start/stop!
        PMC->pc.pcdr.bits.dbgu = 1;

        /* Optimize CPU setting for speed */
        SetDefaultMaster(1);

        return SUCCESS;

    }

    //------------------------------------------------------------------------------
    /// Enable or disable default master access
    /// \param enable 1 enable defaultMaster settings, 0 disable it.
    //------------------------------------------------------------------------------
    void SetDefaultMaster(unsigned char enable) @C() 
    {
        // Set default master
        if (enable == 1) {
            // Set default master: SRAM0 -> Cortex-M3 System
            MATRIX->scfg0.bits.fixed_defmstr = 1;
            MATRIX->scfg0.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_FIXED_DEFAULT;

            // Set default master: SRAM1 -> Cortex-M3 System
            MATRIX->scfg1.bits.fixed_defmstr = 1;
            MATRIX->scfg1.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_FIXED_DEFAULT;

            // Set default master: Internal flash0 -> Cortex-M3 Instruction/Data
            MATRIX->scfg3.bits.fixed_defmstr = 0;
            MATRIX->scfg3.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_FIXED_DEFAULT;
        } else {

            // Clear default master: SRAM0 -> Cortex-M3 System
            MATRIX->scfg0.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_NO_DEFAULT;

            // Clear default master: SRAM1 -> Cortex-M3 System
            MATRIX->scfg1.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_NO_DEFAULT;

            // Clear default master: Internal flash0 -> Cortex-M3 Instruction/Data
            MATRIX->scfg3.bits.defmstr_type = MATRIX_SCFG_MASTER_TYPE_NO_DEFAULT;
        }
    }

    /**
     * informs us when the main clock changes
     */
    async event void HplSam3Clock.mainClockChanged() {}

}

