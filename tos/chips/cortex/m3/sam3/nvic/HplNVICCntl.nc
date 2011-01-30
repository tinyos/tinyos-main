/**
 * "Copyright (c) 2009 The Regents of the University of California.
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
 * Control interface for the NVIC.
 *
 * @author Thomas Schmid
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

interface HplNVICCntl
{
    command void setPriorityGrouping(uint32_t priority_grouping);

	async command void enableUsageFault();
	async command void disableUsageFault();
	async command void enableBusFault();
	async command void disableBusFault();
	async command void enableMemoryProtectionFault();
	async command void disableMemoryProtectionFault();

	async command bool isSVCallPended();
	async command bool isUsageFaultPended();
	async command bool isBusFaultPended();
	async command bool isMemoryProtectionFaultPended();

	async command bool isSysTickActive();
	async command bool isPendSVActive();
	async command bool isMonitorActive();
	async command bool isSVCallActive();
	async command bool isUsageFaultActive();
	async command bool isBusFaultActive();
	async command bool isMemoryProtectionFaultActive();

	command void setSVCallPrio(uint8_t prio);
	command void setPendSVPrio(uint8_t prio);
}
