// $Id: HplAt45dbC.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * AT45DB flash chip HPL for mica family. Each family member must provide
 * and HplAt45dbIOC component implementing the SPIByte and HplAt45dbByte
 * interfaces required by HplAt45dbByteC.
 *
 * @author David Gay
 */

configuration HplAt45dbC {
  provides interface HplAt45db @atmostonce();
}
implementation {
  // 9 because the AT45DB041B has 264 byte pages (log2 page size rounded up)
  components new HplAt45dbByteC(9), HplAt45dbIOC;

  HplAt45db = HplAt45dbByteC;

  HplAt45dbByteC.Resource -> HplAt45dbIOC;
  HplAt45dbByteC.FlashSpi -> HplAt45dbIOC;
  HplAt45dbByteC.HplAt45dbByte -> HplAt45dbIOC;
}
