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

module TestAlarmTMicroP
{
	uses
    {
        interface Leds;
        interface Boot;

        interface Lcd;
        interface Draw;

        interface Alarm<TMicro,uint32_t>;

        interface HplSam3uTCChannel as HilCounter;
    }
}
implementation
{
    uint32_t delta = 1e6;

	event void Boot.booted()
	{
        call Lcd.initialize();
	}

    event void Lcd.initializeDone(error_t err)
    {
        if(err != SUCCESS)
        {
            call Leds.led0On();
            call Leds.led1On();
            call Leds.led2On();
        }
        else
        {
            call Draw.fill(COLOR_WHITE);
            call Lcd.start();
        }
    }

    event void Lcd.startDone()
    {
        uint32_t now = call Alarm.getNow();

        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2Off();


        call Draw.fill(COLOR_WHITE);
        call Draw.drawString(10, 10, "AlarmTest:", COLOR_BLACK);
        call Draw.drawString(10, 50, "Now: ", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 50, now, 1, COLOR_BLACK);
        call Draw.drawString(10, 70, "Alarm: ", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 70, now+delta, 1, COLOR_BLACK);

        call Draw.drawString(10, 110, "Frequency kHz:", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 130, call HilCounter.getTimerFrequency(), 1, COLOR_BLACK);
   
        call Alarm.startAt(now, delta);
    }


    async event void Alarm.fired()
    {
        uint32_t now = call Alarm.getNow();

        call Draw.fill(COLOR_WHITE);
        call Draw.drawString(10, 10, "AlarmTest:", COLOR_BLACK);
        call Draw.drawString(10, 50, "Now: ", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 50, now, 1, COLOR_BLACK);
        call Draw.drawString(10, 70, "Err: ", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 70, now - call Alarm.getAlarm(), 1, COLOR_BLACK);
        call Draw.drawString(10, 90, "Next: ", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 90, now+delta, 1, COLOR_BLACK);

        call Draw.drawString(10, 110, "Frequency kHz:", COLOR_BLACK);
        call Draw.drawInt(BOARD_LCD_WIDTH-20, 130, call HilCounter.getTimerFrequency(), 1, COLOR_BLACK);
   
        call Alarm.startAt(now, delta);
    }

    async event void HilCounter.overflow() {}

}
