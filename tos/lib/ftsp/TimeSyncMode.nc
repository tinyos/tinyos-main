/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 */

/**
  * the time sync module can work in two modes:
  *            - TS_TIMER_MODE (default): TS msgs sent period. from the timer
  *            - TS_USER_MODE: TS msgs sent only when explic. asked by user 
  *                            via TimeSyncMode.send() command, TimeSync.Timer 
  *                            is stopped in this mode
  */
  
interface TimeSyncMode
{
	/**
	 * Sets the current mode of the TimeSync module.
	 * returns FAIL if didn't succeed
	 */
	command error_t setMode(uint8_t mode);

	/**
	 * Gets the current mode of the TimeSync module.
	 */
	command uint8_t getMode();
	
	/**
	 * command to send out time synchronization message.
	 * returns FAIL if TimeSync not in TS_USER_MODE
	 */
	command error_t send();
	
 }


