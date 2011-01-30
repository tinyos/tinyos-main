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
 * Provides a bare bone interface to the SAM3 TC.
 *
 * @author Thomas Schmid
 */

#include "sam3tchardware.h"

generic module HplSam3TCChannelP(uint32_t tc_channel_base) @safe()
{
    provides {
        interface HplSam3TCChannel;
        interface HplSam3TCCapture as Capture;
        interface HplSam3TCCompare as CompareA;
        interface HplSam3TCCompare as CompareB;
        interface HplSam3TCCompare as CompareC;
    }
    uses {
        interface HplSam3Clock as ClockConfig;

        interface HplSam3TCEvent as TimerEvent;
        interface HplNVICInterruptCntl as NVICTCInterrupt;
        interface HplSam3PeripheralClockCntl as TCPClockCntl;

    }
}
implementation
{
    // the CMR registers have slightly different meanings in the two modes!
    volatile tc_channel_capture_t *CH_CAPTURE = (volatile tc_channel_capture_t*)tc_channel_base;
    volatile tc_channel_wave_t *CH_WAVE = (volatile tc_channel_wave_t*)tc_channel_base;

    // interrupt status
    tc_sr_t sr;

    /******************************************
     * General TC Channel functions
     ******************************************/

    async command uint16_t HplSam3TCChannel.get()
    {
        return CH_CAPTURE->cv.bits.cv;
    }

    async command bool HplSam3TCChannel.isOverflowPending()
    {
        sr.flat |= CH_CAPTURE->sr.flat;
        return (sr.bits.covfs && 1);
    }

    async command void HplSam3TCChannel.clearOverflow()
    {
        // read the sr register to clear it
        sr.flat |= CH_CAPTURE->sr.flat;
        // assure that the overlof is cleared
        sr.bits.covfs = 0;
    }

    /**
     * FIXME: this currently only selects between wave mode or non-wave mode.
     * This should be extended to all the different posibilities of modes!
     *
     * allowed arguments:
     *   TC_CMR_WAVE: selects wave mode. Allows compare on A, B, and C or wave
     *                generation
     *   TC_CMR_CAPTURE: selects capture mode (disables wave mode!). Allows
     *                   capture on A, B, and compare on C. (DEFAULT)
     */
    async command void HplSam3TCChannel.setMode(uint8_t mode)
    {
        switch(mode)
        {
            case TC_CMR_WAVE:
                {
                    tc_cmr_wave_t cmr = CH_WAVE->cmr;
                    cmr.bits.wave = (mode & 0x01);
                    CH_WAVE->cmr = cmr;
                }
            case TC_CMR_CAPTURE:
                {
                    tc_cmr_capture_t cmr = CH_CAPTURE->cmr;
                    cmr.bits.wave = (mode & 0x01);
                    CH_CAPTURE->cmr = cmr;
                }
        }
    }

    async command uint8_t HplSam3TCChannel.getMode()
    {
        // the wave field is the same in capture and wave mode!
        return CH_CAPTURE->cmr.bits.wave;
    }

    /**
     * This enables the events for this channel and the peripheral clock!
     */
    async command void HplSam3TCChannel.enableEvents()
    {
        tc_ier_t ier;
        tc_ccr_t ccr;
        ier.flat = 0;
        ccr.flat = 0;

        // enable the peripheral clock to this channel
        call TCPClockCntl.enable();

        call NVICTCInterrupt.configure(0);
        // now enable the IRQ
        call NVICTCInterrupt.enable();
        
        // by default, we enable at least overflows
        ier.bits.covfs = 1;
        CH_CAPTURE->ier = ier;

        // enable the clock
        ccr.bits.clken = 1;
        // start the clock!
        ccr.bits.swtrg = 1;
        CH_CAPTURE->ccr = ccr;
    }

    /**
     * This enables the peripheral clock for this channel
     */
    async command void HplSam3TCChannel.enableClock() {
        // enable the peripheral clock to this channel
        call TCPClockCntl.enable();
    }

    /**
     * This disables the events for this channel and the peripheral clock!
     */
    async command void HplSam3TCChannel.disableEvents()
    {
        tc_idr_t idr;
        idr.flat = 0;

        call NVICTCInterrupt.disable();
        call TCPClockCntl.disable();

        // disable overruns
        idr.bits.covfs = 1;
        CH_CAPTURE->idr = idr;
    }

    /**
     * This disables the peripheral clock for this channel
     */
    async command void HplSam3TCChannel.disableClock() {
        // disable the peripheral clock to this channel
        call TCPClockCntl.disable();
    }

    /**
     * Allowed clock sources:
     * TC_CMR_CLK_TC1: selects MCK/2 
     * TC_CMR_CLK_TC2: selects MCK/8
     * TC_CMR_CLK_TC3: selects MCK/32
     * TC_CMR_CLK_TC4: selects MCK/128
     * TC_CMR_CLK_SLOW: selects SLCK. if MCK=SLCK, then this clock will be
     *                  modified by PRES and MDIV!
     * TC_CMR_CLK_XC0: selects external clock input 0
     * TC_CMR_CLK_XC1: selects external clock input 1
     * TC_CMR_CLK_XC2: selects external clock input 2
     */
    async command void HplSam3TCChannel.setClockSource(uint8_t clockSource)
    {
        // the tcclks is the same in capture and wave!
        tc_cmr_capture_t cmr = CH_CAPTURE->cmr;
        cmr.bits.tcclks = clockSource;
        CH_CAPTURE->cmr = cmr;
    }

    async event void TimerEvent.fired()
    {
        atomic{

            sr.flat |= CH_CAPTURE->sr.flat; // combine the current state for everyone to;

            if(sr.bits.covfs){
                signal HplSam3TCChannel.overflow();
                sr.bits.covfs = 0;
            }
            if(sr.bits.lovrs){
                // only signal if the corresponding capture is enabled
                if(CH_CAPTURE->imr.bits.ldras)
                    signal Capture.overrun();
                if(CH_CAPTURE->imr.bits.ldrbs)
                    signal Capture.overrun();
                sr.bits.lovrs = 0;
            }
            if(sr.bits.cpas){
                signal CompareA.fired();
                sr.bits.cpas = 0;
            }
            if(sr.bits.cpbs){
                signal CompareB.fired();
                sr.bits.cpbs = 0;
            }
            if(sr.bits.cpcs){
	      signal CompareC.fired();
	      sr.bits.cpcs = 0;
            }
            if(sr.bits.ldras){
                signal Capture.captured(call Capture.getEventRA());
                sr.bits.ldras = 0;
            }
            if(sr.bits.ldrbs){
                signal Capture.captured(call Capture.getEventRB());
                sr.bits.ldrbs = 0;
            }
        }
    }

    async command uint32_t HplSam3TCChannel.getTimerFrequency()
    {
        uint32_t mck;

        if(CH_CAPTURE->cmr.bits.tcclks == TC_CMR_CLK_SLOW)
            return 32;

        mck = call ClockConfig.getMainClockSpeed();
        return mck >> ((CH_CAPTURE->cmr.bits.tcclks* 2) + 1);
    }

    async event void ClockConfig.mainClockChanged()
    {
        // in the best case, we would now inform the user!
    }

    default async event void HplSam3TCChannel.overflow(){ }

    /******************************************
     * Capture
     ******************************************/

    async command void Capture.enable()
    {
        tc_ier_t ier;
        ier.bits.ldras = 1;
        ier.bits.ldrbs = 1;
        ier.bits.lovrs = 1;
        CH_CAPTURE->ier = ier;
    }

    async command void Capture.disable()
    {
        tc_idr_t idr;
        // disable interrupt plus overrun
        idr.bits.ldras = 1;
        idr.bits.ldrbs = 1;
        idr.bits.lovrs = 1;
        CH_CAPTURE->idr = idr;
    }

    async command uint16_t Capture.getEventRA()
    {
        return CH_CAPTURE->ra.bits.ra;
    }

    async command uint16_t Capture.getEventRB()
    {
        return CH_CAPTURE->rb.bits.rb;
    }

    async command void Capture.clearPendingEvent()
    {
        sr.flat |= CH_CAPTURE->sr.flat;
        sr.bits.ldras = 0;
        sr.bits.ldrbs = 0;
    }

    async command void Capture.setEdge(uint8_t cm)
    {
        tc_cmr_capture_t cmr = CH_CAPTURE->cmr;
        cmr.bits.ldra = (cm & 0x3);
        cmr.bits.ldrb = (cm & 0x3);
        CH_CAPTURE->cmr = cmr;
    }

    async command void Capture.setExternalTriggerEdge(uint8_t cm)
    {
        tc_cmr_capture_t cmr = CH_CAPTURE->cmr;
        cmr.bits.etrgedg = (cm & 0x3);
        CH_CAPTURE->cmr = cmr;
    }

    async command void Capture.setExternalTrigger(uint8_t cm )
    {
        tc_cmr_capture_t cmr = CH_CAPTURE->cmr;
        cmr.bits.abetrg = (cm & 0x1);
        CH_CAPTURE->cmr = cmr;
    }

    async command bool Capture.isOverrunPending()
    {
        sr.flat |= CH_CAPTURE->sr.flat;
        return (sr.bits.lovrs & 0x01);
    }

    async command void Capture.clearOverrun()
    {
        sr.flat |= CH_CAPTURE->sr.flat;
        sr.bits.lovrs = 0;
    }

    default async event void Capture.overrun() { }
    default async event void Capture.captured(uint16_t time) { }

    /******************************************
     * Compare A
     ******************************************/
    async command void CompareA.enable()
    {
        tc_ier_t ier = CH_WAVE->ier;
        ier.bits.cpas = 1;
        CH_WAVE->ier = ier;
    }

    async command void CompareA.disable()
    {
        tc_idr_t idr = CH_WAVE->idr;
        idr.bits.cpas = 1;
        CH_WAVE->idr = idr;
    }

    async command bool CompareA.isEnabled()
    {
        return (CH_WAVE->imr.bits.cpas & 0x01);
    }

    async command void CompareA.clearPendingEvent()
    {
        sr.flat |= CH_WAVE->sr.flat;
        sr.bits.cpas = 0;
    }

    async command uint16_t CompareA.getEvent()
    {
        return CH_WAVE->ra.bits.ra;
    }

    async command void CompareA.setEvent( uint16_t time )
    {
        tc_ra_t ra = CH_WAVE->ra;
        ra.bits.ra = time;
        CH_WAVE->ra = ra;
    }

    async command void CompareA.setEventFromPrev( uint16_t delta )
    {
        tc_ra_t ra = CH_WAVE->ra;
        ra.bits.ra += delta;
        CH_WAVE->ra = ra;
    }

    async command void CompareA.setEventFromNow( uint16_t delta )
    {
        tc_ra_t ra = CH_WAVE->ra;
        ra.bits.ra = CH_WAVE->cv.bits.cv + delta;
        CH_WAVE->ra = ra;
    }

    default async event void CompareA.fired() { }


    /******************************************
     * Compare B
     ******************************************/
    async command void CompareB.enable()
    {
        tc_ier_t ier = CH_WAVE->ier;
        ier.bits.cpbs = 1;
        CH_WAVE->ier = ier;
    }

    async command void CompareB.disable()
    {
        tc_idr_t idr = CH_WAVE->idr;
        idr.bits.cpbs = 1;
        CH_WAVE->idr = idr;
    }

    async command bool CompareB.isEnabled()
    {
        return (CH_WAVE->imr.bits.cpbs & 0x01);
    }

    async command void CompareB.clearPendingEvent()
    {
        sr.flat |= CH_WAVE->sr.flat;
        sr.bits.cpbs = 0;
    }

    async command uint16_t CompareB.getEvent()
    {
        return CH_WAVE->rb.bits.rb;
    }

    async command void CompareB.setEvent( uint16_t time )
    {
        tc_rb_t rb = CH_WAVE->rb;
        rb.bits.rb = time;
        CH_WAVE->rb = rb;
    }

    async command void CompareB.setEventFromPrev( uint16_t delta )
    {
        tc_rb_t rb = CH_WAVE->rb;
        rb.bits.rb += delta;
        CH_WAVE->rb = rb;
    }

    async command void CompareB.setEventFromNow( uint16_t delta )
    {
        tc_rb_t rb = CH_WAVE->rb;
        rb.bits.rb = CH_WAVE->cv.bits.cv + delta;
        CH_WAVE->rb = rb;
    }

    default async event void CompareB.fired() { }


    /******************************************
     * Compare C
     ******************************************/
    async command void CompareC.enable()
    {
        tc_ier_t ier = CH_WAVE->ier;
        ier.bits.cpcs = 1;
        CH_WAVE->ier = ier;
    }

    async command void CompareC.disable()
    {
        tc_idr_t idr = CH_WAVE->idr;
        idr.bits.cpcs = 1;
        CH_WAVE->idr = idr;
    }

    async command bool CompareC.isEnabled()
    {
        return (CH_WAVE->imr.bits.cpcs & 0x01);
    }

    async command void CompareC.clearPendingEvent()
    {
        sr.flat |= CH_WAVE->sr.flat;
        sr.bits.cpcs = 0;
    }

    async command uint16_t CompareC.getEvent()
    {
        return CH_WAVE->rc.bits.rc;
    }

    async command void CompareC.setEvent( uint16_t time )
    {
        tc_rc_t rc = CH_WAVE->rc;
        rc.bits.rc = time;
        CH_WAVE->rc = rc;
    }

    async command void CompareC.setEventFromPrev( uint16_t delta )
    {
        tc_rc_t rc = CH_WAVE->rc;
        rc.bits.rc += delta;
        CH_WAVE->rc = rc;
    }

    async command void CompareC.setEventFromNow( uint16_t delta )
    {
        tc_rc_t rc = CH_WAVE->rc;
        rc.bits.rc = CH_WAVE->cv.bits.cv + delta;
        CH_WAVE->rc = rc;
    }

    default async event void CompareC.fired() { }
}

