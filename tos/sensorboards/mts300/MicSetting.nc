// $Id: MicSetting.nc,v 1.2 2008-06-11 00:46:27 razvanm Exp $

/*
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
 * The microphone on the mica sensor board has two methods for control and
 * one method to read the binary output of the tone detector.  (Note:  The tone
 * detector's binary output can be configured as an interrupt.  Please see MicInterrupt.ti)
 *
 * muxSel allows users to switch the ADC to sample from phase lock loop output of
 * the tone detector (by setting the value to 0 (default))  or the raw voice-band output 
 * of the micrphone (by setting the value to 1).
 *
 * gainAdjust allows users to adjust the amplification gain on the microphone. The range
 * is 0 to 255 with 0 being the minmum and 255 being the maximum amplification.  Note that
 * setting amplification too high can result in clipping (signal distortion).
 *
 * If an audio signal at 4.3kHz is picked up by the microphone, the tone
 * detect will decode it and generate a binary ouput (0 meaning tone is detected, 1 meaning
 * tone is not detected).  Users can read this output simply by calling readToneDetector().
 *
 */

/**
 * @author Alec Woo
 */

interface MicSetting {
  /* Effect:  Set the multiplexer's setting on the microphone
   * Return:  returns SUCCESS or FAIL
   */
  command error_t muxSel(uint8_t sel);
  /* Effect:  Set the amplificatoin gain  on the microphone
   * Return:  returns SUCCESS or FAIL
   */
  command error_t gainAdjust(uint8_t val);

  /* Effect:  returns the binary tone detector's output
   * Return:  0 meaning tone is detected, 1 meanning tone is not detected
   */
  command uint8_t readToneDetector();
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
