/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

