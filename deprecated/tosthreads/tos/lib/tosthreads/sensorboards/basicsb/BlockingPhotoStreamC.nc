/* $Id: BlockingPhotoStreamC.nc,v 1.1 2008-06-14 19:27:25 klueska Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Photodiode of the basicsb sensor board.
 * 
 * @author David Gay
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

generic configuration BlockingPhotoStreamC() {
  provides interface BlockingReadStream<uint16_t>;
}
implementation {
  components PhotoDeviceP, new BlockingAdcReadStreamClientC();

  BlockingReadStream = BlockingAdcReadStreamClientC;
  BlockingAdcReadStreamClientC.Atm128AdcConfig -> PhotoDeviceP;
  BlockingAdcReadStreamClientC.ResourceConfigure -> PhotoDeviceP;
}
