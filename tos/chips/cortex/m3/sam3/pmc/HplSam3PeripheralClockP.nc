/* "Copyright (c) 2009 The Regents of the University of California.
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
 * Generic module representing a peripheral clock.
 *
 * @author Thomas Schmid
 */

#include "pmchardware.h"

generic module HplSam3PeripheralClockP (uint8_t pid, uint32_t pio_addr) @safe()
{
    provides
    {
        interface HplSam3PeripheralClockCntl as Cntl;
    }
}

implementation
{
    async command void Cntl.enable()
    {
        pmc_pcer_t pcer = ((volatile pmc_pc_t *) (pio_addr))->pcer;
        pcer.flat |= ( 1 << pid );
        ((volatile pmc_pc_t *) (pio_addr))->pcer = pcer;
    }

    async command void Cntl.disable()
    {
        pmc_pcdr_t pcdr = ((volatile pmc_pc_t *) (pio_addr))->pcdr;
        pcdr.flat |= ( 1 << pid );
        ((volatile pmc_pc_t *) (pio_addr))->pcdr = pcdr;

    }

    async command bool Cntl.status()
    {
        if(((volatile pmc_pc_t *) (pio_addr))->pcsr.flat & (1 << pid))
            return TRUE;
        else
            return FALSE;
    }
}
