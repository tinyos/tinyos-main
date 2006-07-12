/* $Id: DemoSensorStreamC.nc,v 1.2 2006-07-12 17:03:14 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Demo sensor for basicsb sensorboard.
 * 
 * @author David Gay
 */

generic configuration DemoSensorStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components new PhotoStreamC() as SensorStream;

  ReadStream = SensorStream;
}
