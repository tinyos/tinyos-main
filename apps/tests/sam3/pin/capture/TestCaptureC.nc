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

module TestCaptureC
{
	uses 
    {
        interface Leds;
        interface Boot;
        interface Lcd;
        interface Draw;

        interface GpioCapture as Capture;
        interface GeneralIO as SFD;

        interface Init as InitAlarm;
        interface Alarm<T32khz,uint32_t> as Alarm32;
    } 
}
implementation
{
    bool falling;
    uint32_t lastTime;

	event void Boot.booted()
	{
        atomic lastTime = 0;

        call InitAlarm.init();

        call Lcd.initialize();
    }

    event void Lcd.initializeDone(error_t result)
    {
        if(result != SUCCESS)
        {
            call Leds.led0On();
        } else {
            call Draw.fill(COLOR_WHITE);
            call Lcd.start();
        }
    }

    event void Lcd.startDone()
    {
        atomic falling = TRUE;
        call SFD.makeInput();
        call Capture.captureRisingEdge();
        call Draw.drawString(10, 10, "Rising on PA0", COLOR_BLACK);
	}

    async event void Capture.captured(uint16_t time)
    {
        uint32_t now = (call Alarm32.getNow() & 0xFFFF0000L) + time;
        call Draw.fill(COLOR_WHITE);
        call Leds.led0Toggle();

        atomic
        {
            if(falling)
            {
                call Draw.drawString(10, 10, "Rising at:", COLOR_BLACK);
                call Draw.drawInt(BOARD_LCD_WIDTH - 10, 30, now, 1, COLOR_BLACK);
                call Draw.drawString(10, 50, "Since last:", COLOR_BLACK);
                call Draw.drawInt(BOARD_LCD_WIDTH - 10, 70, now-lastTime, 1, COLOR_BLACK);

                falling = FALSE;
                call Capture.captureFallingEdge();
            } else {
                call Draw.drawString(10, 10, "Falling at:", COLOR_BLACK);
                call Draw.drawInt(BOARD_LCD_WIDTH - 10, 30, now, 1, COLOR_BLACK);
                call Draw.drawString(10, 50, "Since last:", COLOR_BLACK);
                call Draw.drawInt(BOARD_LCD_WIDTH - 10, 70, now-lastTime, 1, COLOR_BLACK);

                falling = TRUE;
                call Capture.captureRisingEdge();
            }
            lastTime = now;
        }
    }


    async event void Alarm32.fired() {}


}
