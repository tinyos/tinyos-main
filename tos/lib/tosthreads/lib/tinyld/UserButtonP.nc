/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Andew's timer debouce logic used from the CountInput application.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Andrew Redfern <aredfern@kingkong.me.berkeley.edu>
 */

module UserButtonP
{
  provides {
    interface Init;
    interface UserButton;
  }
  uses {
    interface HplMsp430GeneralIO;
    interface HplMsp430Interrupt;
    interface Timer<TMilli>;
  }
}
implementation
{
  command error_t Init.init()
  {
    atomic {
      call HplMsp430Interrupt.disable();
      call HplMsp430GeneralIO.makeInput();
      call HplMsp430GeneralIO.selectIOFunc();
      call HplMsp430Interrupt.edge(TRUE);
      call HplMsp430Interrupt.clear();
      call HplMsp430Interrupt.enable();
    }
    return SUCCESS;
  }

  event void Timer.fired()
  {
    atomic {
      call HplMsp430Interrupt.clear();
      call HplMsp430Interrupt.enable();
    }
  }

  task void debounce()
  {
    call Timer.startOneShot(100);
    signal UserButton.fired();
  }

  async event void HplMsp430Interrupt.fired()
  {
    atomic {
      call HplMsp430Interrupt.disable();
      post debounce();
    }
  }
}

