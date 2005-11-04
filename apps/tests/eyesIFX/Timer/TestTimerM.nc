// $Id: TestTimerM.nc,v 1.1.1.1 2005-11-04 18:20:17 kristinwright Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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

module TestTimerM {
  uses {
    interface Boot;
    interface Alarm<TMilli, uint32_t> as Timer0;
		interface Alarm<TMilli, uint32_t> as Timer1;
		interface Alarm<TMilli, uint32_t> as Timer2;
		interface Alarm<TMilli, uint32_t> as Timer3;
		interface Alarm<TMilli, uint32_t> as Timer4;
		interface Alarm<TMilli, uint32_t> as Timer5;
		interface Alarm<TMilli, uint32_t> as Timer6;
		interface Alarm<TMilli, uint32_t> as Timer7;
		interface Alarm<TMilli, uint32_t> as Timer8;
  }
}

implementation {

  #define DELAY  20
  
  event void Boot.booted() {
	  call Timer0.start(DELAY);
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/   

  async event void Timer0.fired() {
		call Timer1.start(DELAY);
  }
  async event void Timer1.fired() {
		call Timer2.start(DELAY);	
  }
  async event void Timer2.fired() {
		call Timer3.start(DELAY);
  }
  async event void Timer3.fired() {
		call Timer4.start(DELAY);	
  }
  async event void Timer4.fired() {
		call Timer5.start(DELAY);		
  }	
  async event void Timer5.fired() {
		call Timer6.start(DELAY);
  }
  async event void Timer6.fired() {
		call Timer7.start(DELAY);
  }	
  async event void Timer7.fired() {
		call Timer8.start(DELAY);			
  }	
  async event void Timer8.fired() {
		call Timer0.start(DELAY);		
  }					
  
}


