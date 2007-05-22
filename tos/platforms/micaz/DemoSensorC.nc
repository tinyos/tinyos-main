/* $Id: DemoSensorC.nc,v 1.5 2007-05-22 20:59:01 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The micaZ doesn't have any built-in sensors - the DemoSensor returns
 * a constant value of 0xbeef, or just reads the ground value for the
 * stream sensor.
 *
 * @author Philip Levis
 * @authod David Gay
 */

generic configuration DemoSensorC()
{
  provides interface Read<uint16_t>;
}
implementation
{
  components new VoltageC() as DemoChannel;

  Read = DemoChannel;
}
