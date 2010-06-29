/*
 * Copyright (c) 2005 Washington University in St. Louis.
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
 */
 
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 */

/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.6 $
 * $Date: 2010-06-29 22:07:46 $ 
 * ======================================================================== 
 */ 

/**
 * Please refer to TEP 115 for more information about this interface and its
 * intended use.<br><br>
 *
 * This is the split-phase counterpart to the StdContol interface.  It
 * should be used for switching between the on and off power states of
 * the component providing it.  For each <code>start()</code> or
 * <code>stop()</code> command, if the command returns SUCCESS, then a
 * corresponding  <code>startDone()</code> or <code>stopDone()</code> event
 * must be signalled.
 *
 * @author Joe Polastre
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */

interface SplitControl
{
  /**
   * Start this component and all of its subcomponents.  Return
   * values of SUCCESS will always result in a <code>startDone()</code>
   * event being signalled.
   *
   * @return SUCCESS if the device is already in the process of 
   *         starting or the device was off and the device is now ready to turn 
   *         on.  After receiving this return value, you should expect a 
   *         <code>startDone</code> event in the near future.<br>
   *         EBUSY if the component is in the middle of powering down
   *               i.e. a <code>stop()</code> command has been called,
   *               and a <code>stopDone()</code> event is pending<br>
   *         EALREADY if the device is already on <br>
   *         FAIL Otherwise
   */
  command error_t start();

  /** 
   * Notify caller that the component has been started and is ready to
   * receive other commands.
   *
   * @param <b>error</b> -- SUCCESS if the component was successfully
   *                        turned on, FAIL otherwise
   */
  event void startDone(error_t error);

  /**
   * Start this component and all of its subcomponents.  Return
   * values of SUCCESS will always result in a <code>startDone()</code>
   * event being signalled.
   *
   * @return SUCCESS if the device is already in the process of 
   *         stopping or the device was on and the device is now ready to turn 
   *         off.  After receiving this return value, you should expect a 
   *         <code>stopDone</code> event in the near future.<br>
   *         EBUSY if the component is in the middle of powering up
   *               i.e. a <code>start()</code> command has been called,
   *               and a <code>startDone()</code> event is pending<br>
   *         EALREADY if the device is already off <br>
   *         FAIL Otherwise
   */
  command error_t stop();

  /**
   * Notify caller that the component has been stopped.
   *
  * @param <b>error</b> -- SUCCESS if the component was successfully
  *                        turned off, FAIL otherwise
   */
  event void stopDone(error_t error);
}
