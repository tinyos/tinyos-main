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
 * Basic application that tests the SAM3U Captures. Connect a switch to PA1
 * and watch the LCD for rising/falling time measurements. 
 *
 * @author Thomas Schmid
 **/

configuration TestCaptureAppC
{
}
implementation
{
	components MainC, TestCaptureC, LedsC, LcdC;

	TestCaptureC -> MainC.Boot;
	TestCaptureC.Leds -> LedsC;
    TestCaptureC.Lcd -> LcdC;
    TestCaptureC.Draw -> LcdC;

    components HplSam3uGeneralIOC as GeneralIOC;
    components HplSam3TCC;
    components new GpioCaptureC() as CaptureSFDC;

    CaptureSFDC.TCCapture -> HplSam3TCC.TC0Capture;
    CaptureSFDC.GeneralIO -> GeneralIOC.HplPioA1;

    TestCaptureC.Capture -> CaptureSFDC;
    TestCaptureC.SFD -> GeneralIOC.PioA1;

    components new Alarm32khz32C();

    TestCaptureC.InitAlarm -> Alarm32khz32C;
    TestCaptureC.Alarm32 -> Alarm32khz32C;

}
