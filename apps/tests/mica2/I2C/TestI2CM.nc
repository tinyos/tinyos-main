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
 *  $Id: TestI2CM.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $
 */

/**
 * Implementation for TestI2C application:  
 *   Yellow      == Every timer, post task for I2C ping if not already running
 *   Red & GREEN == task started
 *   Red         == Device ping FAIL
 *   Green       == Device ping SUCCESS
 *
 * @version    2005/9/11    mturon     Initial version
 */

#define I2C_DEVICE      I2C_MTS300_MIC

#define I2C_MTS310_MAG  0x58
#define I2C_MTS300_MIC  0x5A
#define I2C_MDA300_ADC  0x94
#define I2C_MDA300_EE   0xAE

#include "Timer.h"

module TestI2CM
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
  uses interface HplAtm128I2CBus    as I2C;
}
implementation
{
    bool    working;

    task void i2c_test() {
	call Leds.led1On();
	call Leds.led0On();
	
	if (call I2C.ping(I2C_DEVICE) == SUCCESS) {
	    call Leds.led0Off();
	} else {
	    call Leds.led1Off();
	}

	working = FALSE;
    }

    void i2c_test_start() {
	atomic {
	    if (!working) {
		working = TRUE;
		post i2c_test();
	    }
	}
    }

    event void Boot.booted() {
	working = FALSE;
	call I2C.init();

	call Timer0.startPeriodic( 10000 );

	call Leds.led2On();
	i2c_test_start();
    }
    
    event void Timer0.fired() {
	call Leds.led2Toggle();
	i2c_test_start();
    }  

    async event void I2C.symbolSent() { }

}

