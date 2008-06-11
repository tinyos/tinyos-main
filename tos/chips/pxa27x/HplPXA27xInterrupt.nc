// $Id: HplPXA27xInterrupt.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/**
 * This interface supports the core peripheral interrupts of the PXA27X 
 * processor.  
 * It is usually parameterized based on the Peripheral ID (PPID) of the 
 * interrupt signal.
 * ARM interrupt levels (IRQ/FIQ) are established by wiring.
 * Priorities are established by a static table (TOSH_IRP_TABLE)
 *
 * Components implementing this interface are expected to provide reentrant
 * (i.e. atomic) semantics.
 *
 * @author: Philip Buonadonna
 */

interface HplPXA27xInterrupt
{
  /** 
   * Allocates a given peripheral interrupt with the PXA27X interrupt manager.
   * Specifically, it establishes the interrupt level (IRQ or FIQ) and the 
   * priority. 
   */
  async command error_t allocate();

  /**
   * Enables a periperhal interrupt.
   */
  async command void enable();

  /**
   * Disables a peripheral interrupt.
   */
  async command void disable();

  /**
   * The peripheral interrupt event.
   */
  async event void fired();
}
