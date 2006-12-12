/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: TestMts300P.nc,v 1.4 2006-12-12 18:22:52 vlahan Exp $
 */

#include "Timer.h"

/**
 * This application tests the mts300 sensorboard.
 * Specifically, this handles the thermistor and light sensors.
 * 
 * @author  Martin Turon
 * @date    October 19, 2005
 */
module TestMts300P
{
    uses {
	interface Boot;
	interface Leds;
	interface Timer<TMilli> as AppTimer;

	interface StdControl as SensorControl;
	interface AcquireData as Temp;
	interface AcquireData as Light;
    }
}
implementation
{
    event void Boot.booted() {
	call Leds.led0On();
	call Leds.led1On();        // power led
	call SensorControl.start();
    }
    
    event void AppTimer.fired() {
	call Leds.led0Toggle();    // heartbeat indicator 
	call Light.getData();
	call Temp.getData();
    }

    event void Light.dataReady(uint16_t data) {
	call Leds.led1Toggle();
    }

    event void Temp.dataReady(uint16_t data) {
	call Leds.led2Toggle();
    }

    event void Light.error(uint16_t info) {
    }

    event void Temp.error(uint16_t info) {
    }
}

