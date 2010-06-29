// $Id: TestTimerM.nc,v 1.5 2010-06-29 22:07:36 scipio Exp $

/*                                  tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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


