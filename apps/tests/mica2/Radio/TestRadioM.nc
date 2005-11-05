// $Id: TestRadioM.nc,v 1.1.1.1 2005-11-05 16:38:03 kristinwright Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for TestRadio application.  Toggle the red LED when a
 * Timer fires.
 **/

includes Timer;

module TestRadioM
{
  uses interface Timer<TMilli> as Timer0;
  uses interface SplitControl;
  uses interface Send;
  uses interface Receive;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
  message_t msg;

  event void Boot.booted()
  {
    call SplitControl.start();
  }

  event void SplitControl.startDone(error_t error) {
    call Timer0.startPeriodic( 1000 );
  }

  event void SplitControl.stopDone(error_t error) {
  }

  event void Timer0.fired()
  {
    call Leds.led0Toggle();
    msg.header.addr = 0xffff;
    msg.header.group = 0x42;
    msg.data[0] = 0xaa;
    msg.data[1] = 0xbb;
    msg.header.length = 2;
    if (call Send.send(&msg, 2) == SUCCESS)
      call Leds.led1Toggle();
  }

  event void Send.sendDone(message_t* mmsg, error_t error) {
    call Leds.led2Toggle();
  }

  event message_t* Receive.receive(message_t* mmsg, void* payload, uint8_t len) {
    return mmsg;
  }
}

