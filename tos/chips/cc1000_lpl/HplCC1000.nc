// $Id: HplCC1000.nc,v 1.4 2006-12-12 18:23:05 vlahan Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 *
 */

/**
 * Low-level CC1000 radio-access operations that must be provided by a
 * platform wishing to use this CC1000 implementation.
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


interface HplCC1000 {
  /**
   * Initialize CC1K pins
   */
  command void init();

  /**
   * Write a value to a CC1000 register.
   * @param addr Which CC1000 register
   * @param data Value to write
   */
  async command void write(uint8_t addr, uint8_t data);

  /**
   * Read a value from a CC1000 register.
   * @param addr Which CC1000 register
   * @return Value of register
   */
  async command uint8_t read(uint8_t addr);

  /**
   * Read the state of the CHP_OUT pin
   * @return State of CHP_OUT as a boolean (TRUE for high)
   */
  async command bool getLOCK();
}
