/// $Id: Atm128SpiC.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $

/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University  of California.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * The HAL of the SPI bus on the atm128.
 *
 * <pre>
 *  $Id: Atm128SpiC.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $
 * </pre>
 *
 *
 * @author Philip Levis
 * @author Martin Turon
 * @author Joe Polastre
 * @date   September 7 2005
 */

configuration Atm128SpiC {
  provides interface Init;
  provides interface SpiByte;
  provides interface SpiPacket;
  provides interface Resource[uint8_t id];
}
implementation {
  components Atm128SpiP as SpiMaster, HplAtm128SpiC as HplSpi;
  components HplAtm128GeneralIOC as IO;
  components new SimpleFcfsArbiterC("Atm128SpiC.Resource") as Arbiter;
  components McuSleepC;
  
  Init         = SpiMaster;
  
  SpiByte      = SpiMaster;
  SpiPacket    = SpiMaster;
  Resource     = SpiMaster;

  SpiMaster.ResourceArbiter -> Arbiter;
  SpiMaster.ArbiterInfo    -> Arbiter;
  SpiMaster.Spi             -> HplSpi;
  SpiMaster.McuPowerState   -> McuSleepC;
}
