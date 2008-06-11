// $Id: HplCC1000C.nc,v 1.6 2008-06-11 00:46:26 razvanm Exp $
/*
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
 * HPL for the CC1000 radio, for the mica2 platform.
 *
 * @author David Gay
 */
configuration HplCC1000C {
  provides {
    interface ReadNow<uint16_t> as RssiAdc;
    interface Resource as RssiResource;
    interface HplCC1000Spi;
    interface HplCC1000;
  }
}
implementation {
  components HplCC1000P, HplCC1000SpiP;
  components new AdcReadNowClientC() as RssiChannel;

  HplCC1000 = HplCC1000P;
  HplCC1000Spi = HplCC1000SpiP;
  RssiAdc = RssiChannel;
  RssiResource = RssiChannel;

  RssiChannel.Atm128AdcConfig -> HplCC1000P;

  // HplCC1000M, HplCC1000SpiM are wired in HplCC1000InitC which is always
  // included (see MotePlatformC.nc).
}
