// $Id: TestLocalTimeAppC.nc,v 1.1 2007-05-23 22:00:55 idgay Exp $

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
 * Copyright (c) 2002-2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * TestLocalTime is a simple application that tests the LocalTimeMilliC
 * componentby sending the current time over the serial port once per
 * second.
 *
 *  @author David Gay
 *  @author Gilman Tolle
 *  @author Philip Levis
 *  
 *  @date   May 24 2007
 *
 **/

#include "TestLocalTime.h"

configuration TestLocalTimeAppC {}
implementation {
  components TestLocalTimeC as App, LedsC, MainC;
  components SerialActiveMessageC as AM;
  components new TimerMilliC(), LocalTimeMilliC;

  App.Boot -> MainC.Boot;
  App.Control -> AM;
  App.AMSend -> AM.AMSend[AM_TEST_LOCALTIME_MSG];
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.LocalTime -> LocalTimeMilliC;
}


