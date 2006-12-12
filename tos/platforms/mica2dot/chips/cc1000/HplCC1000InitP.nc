// $Id: HplCC1000InitP.nc,v 1.4 2006-12-12 18:23:43 vlahan Exp $
/*									tab:4
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Hardware initialisation for the CC1000 radio. This component is always
 * included even if the radio is not used.
 *
 * @author David Gay
 */
configuration HplCC1000InitP {
  provides interface Init as PlatformInit;
}
implementation {
  components HplCC1000P, HplCC1000SpiP, HplAtm128GeneralIOC as IO;

  PlatformInit = HplCC1000P;
  PlatformInit = HplCC1000SpiP;

  HplCC1000P.CHP_OUT -> IO.PortE7;
  HplCC1000P.PALE -> IO.PortD5;
  HplCC1000P.PCLK -> IO.PortD6;
  HplCC1000P.PDATA -> IO.PortD7;

  HplCC1000SpiP.SpiSck -> IO.PortB1;
  HplCC1000SpiP.SpiMiso -> IO.PortB3;
  HplCC1000SpiP.SpiMosi -> IO.PortB2;
  HplCC1000SpiP.OC1C -> IO.PortB7;
}
