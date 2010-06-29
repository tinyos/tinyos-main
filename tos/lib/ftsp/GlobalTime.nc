/*
 * Copyright (c) 2002, Vanderbilt University
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
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 */
#include "Timer.h"

interface GlobalTime<precision_tag>
{
	/**
	 * Returns the current local time of this mote.
	 */
	async command uint32_t getLocalTime();

	/**
	 * Reads the current global time. This method is a combination
	 * of <code>getLocalTime</code> and <code>local2Global</code>.
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command error_t getGlobalTime(uint32_t *time);

	/**
	 * Converts the local time given in <code>time</code> into the
	 * corresponding global time and stores this again in
	 * <code>time</code>. The following equation is used to compute the
	 * conversion:
	 *
	 *	globalTime = localTime + offset + skew * (localTime - syncPoint)
	 *
	 * The skew is normalized to 0.0 (1.0 is subtracted) to increase the
	 * machine precision. The syncPoint value is periodically updated to
	 * increase the machine precision of the floating point arithmetic and
	 * also to allow time wrap.
	 *
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command error_t local2Global(uint32_t *time);

	/**
	 * Converts the global time given in <code>time</code> into the
	 * correspoding local time and stores this again in
	 * <code>time</code>. This method performs the inverse of the
	 * <code>local2Global</clode> transformation.
	 *
	 * @return SUCCESS if this mote is synchronized, FAIL otherwise.
	 */
	async command error_t global2Local(uint32_t *time);
}
