/**
 * Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:  
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 **/

#include <color.h>
#include <lcd.h>
#include <sam3upmchardware.h>

module ClockSpeedC
{
	uses
    {
        interface Leds;
        interface Boot;

        interface HplSam3uClock;

        interface HplSam3uGeneralIOPin as Pck0Pin;

        interface Timer<TMilli> as ChangeTimer;

        interface Lcd;
        interface Draw;
    }
}
implementation
{
    uint8_t state;
    uint8_t speed;

    enum {
        SLOW = 0,
        MAIN = 1,
        PLLA = 2,
        MASTER = 4,
    };

    enum {
        RC12,
        MC48,
        MC84,
    };

	event void Boot.booted()
	{
        pmc_pck_t pck0 = PMC->pck0;
        pmc_scer_t scer = PMC->scer;

        state = SLOW;
        speed = RC12;

        // output slow clock on PCK0
        pck0.bits.css = SLOW;
        PMC->pck0 = pck0;

        scer.bits.pck0 = 1;
        PMC->scer = scer;

        call Lcd.initialize();

        call Pck0Pin.disablePioControl();
        call Pck0Pin.selectPeripheralB(); // output programmable clock 0 on pin
	}

    event void Lcd.initializeDone(error_t err)
    {
        if(err != SUCCESS)
        {
            call Leds.led1On();
        }
        else
        {
            call Draw.fill(COLOR_WHITE);
            call Lcd.start();
        }
    }

    event void Lcd.startDone()
    {
        call Leds.led0On();
        call Draw.drawString(10, 10, "Init Clock:", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 30, call HplSam3uClock.getMainClockSpeed(), 1, COLOR_BLACK);
        call HplSam3uClock.mckInit84();
        call ChangeTimer.startPeriodic(10000);
    }

    event void ChangeTimer.fired()
    {
        pmc_pck_t pck0 = PMC->pck0;
        call Draw.fill(COLOR_WHITE);

        call Draw.drawString(10, 50, "MCK Speed:", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 70, call HplSam3uClock.getMainClockSpeed(), 1, COLOR_BLACK);

        switch(state)
        {
            case SLOW:
                pck0.bits.css = state;
                PMC->pck0 = pck0;
                call Draw.drawString(10, 90, "Slow Clock on PA21", COLOR_BLACK);
                state = MAIN;
                break;
            case MAIN:
                pck0.bits.css = state;
                PMC->pck0 = pck0;
                call Draw.drawString(10, 90, "Main Clock on PA21", COLOR_BLACK);
                state = PLLA;
                break;
            case PLLA:
                pck0.bits.css = state;
                PMC->pck0 = pck0;
                call Draw.drawString(10, 90, "PLLA Clock on PA21", COLOR_BLACK);
                state = MASTER;
                break;
            case MASTER:
                pck0.bits.css = state;
                PMC->pck0 = pck0;
                call Draw.drawString(10, 90, "Master Clock on PA21", COLOR_BLACK);
                state = SLOW;
                switch(speed)
                {
                    case RC12:
                        call Draw.drawString(10, 10, "RC12 Clock:", COLOR_BLACK);
                        call HplSam3uClock.mckInit12RC();
                        speed = MC48;
                        break;
                    case MC48:
                        call Draw.drawString(10, 10, "MC48 Clock:", COLOR_BLACK);
                        call HplSam3uClock.mckInit84();
                        speed = MC84;
                        break;
                    case MC84:
                        call Draw.drawString(10, 10, "MC84 Clock:", COLOR_BLACK);
                        call HplSam3uClock.mckInit48();
                        speed = RC12;
                        break;
                }
                break;
        }
    }

    async event void HplSam3uClock.mainClockChanged()
    {
    }
}
