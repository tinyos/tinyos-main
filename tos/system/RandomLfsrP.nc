// $Id: RandomLfsrP.nc,v 1.4 2006-12-12 18:23:47 vlahan Exp $

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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 *
 * Authors:		Alec Woo, David Gay, Philip Levis
 * Date last modified:  8/8/05
 *
 */

/**
 * This is a 16 bit Linear Feedback Shift Register pseudo random number
   generator. It is faster than the MLCG generator, but the numbers generated
 * have less randomness.
 *
 * @author Alec Woo
 * @author David Gay
 * @author Philip Levis
 * @date   August 8 2005
 */

module RandomLfsrP
{
  provides interface Init;
  provides interface Random;
}
implementation
{
  uint16_t shiftReg;
  uint16_t initSeed;
  uint16_t mask;

  /* Initialize the seed from the ID of the node */
  command error_t Init.init() {
    atomic {
      shiftReg = 119 * 119 * (TOS_NODE_ID + 1);
      initSeed = shiftReg;
      mask = 137 * 29 * (TOS_NODE_ID + 1);
    }
    return SUCCESS;
  }

  /* Return the next 16 bit random number */
  async command uint16_t Random.rand16() {
    bool endbit;
    uint16_t tmpShiftReg;
    atomic {
      tmpShiftReg = shiftReg;
      endbit = ((tmpShiftReg & 0x8000) != 0);
      tmpShiftReg <<= 1;
      if (endbit) 
	tmpShiftReg ^= 0x100b;
      tmpShiftReg++;
      shiftReg = tmpShiftReg;
      tmpShiftReg = tmpShiftReg ^ mask;
    }
    return tmpShiftReg;
  }

  async command uint32_t Random.rand32() {
    return (uint32_t)call Random.rand16() << 16 | call Random.rand16();
  }
}
