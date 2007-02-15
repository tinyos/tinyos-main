// $Id: MicInterrupt.nc,v 1.1 2007-02-15 10:33:38 pipeng Exp $

/*									tab:4
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
/*
 * Authors:		Alec Woo
 * Date last modified:  8/20/02
 * 
 * The microphone on the mica sensor board has the tone detector interrupt.
 * If an audio signal at 4.3kHz is picked up by the microphone, the tone
 * detect will decode it and generate a toneDetected interrupt if the
 * interrupt is enabled.
 *
 */

/**
 * @author Alec Woo
 */



interface MicInterrupt
{
  /* Effects: disable interrupts
     Returns: SUCCESS
  */
  async command error_t disable();

  /* Effects: enable interrupts
     Returns: SUCCESS
  */
  async command error_t enable();

  /* Interrupt signal for tone detected.  Note that MicInterrupt is automatically disabled
   * before this event is signaled.  (Upper layer needs to reenable this interrupt for future
   * tone detect.
   *
   *  Returns: SUCCESS
   */
  async event error_t toneDetected();
}
