// $Id: TestLplAppC.nc,v 1.5 2010-01-14 15:46:26 klueska Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Simple test code for low-power-listening. Sends a sequence of packets,
 * changing the low-power-listening settings every ~32s. See README.txt
 * for more details.
 *
 *  @author Philip Levis, David Gay
 *  @date   Oct 27 2006
 */

configuration TestLplAppC {}
implementation {
  components MainC, TestLplC as App, LedsC;
  components ActiveMessageC;
  components new TimerMilliC();
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000CsmaRadioC as LplRadio;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSB) || defined(PLATFORM_SHIMMER) || defined(PLATFORM_SHIMMER2) || defined(PLATFORM_INTELMOTE2) || defined(PLATFORM_EPIC)
  components CC2420ActiveMessageC as LplRadio;
#elif defined(PLATFORM_IRIS) || defined(PLATFORM_MULLE)
  components RF230ActiveMessageC as LplRadio;
#elif defined(PLATFORM_EYESIFXV1) || defined(PLATFORM_EYESIFXV2)
  components LplC as LplRadio;
#else
#error "LPL testing not supported on this platform"
#endif
    
  App.Boot -> MainC.Boot;

  App.Receive -> ActiveMessageC.Receive[240];
  App.AMSend -> ActiveMessageC.AMSend[240];
  App.SplitControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.LowPowerListening -> LplRadio;
}


