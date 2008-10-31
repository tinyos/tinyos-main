// $Id: HplDs2401C.nc,v 1.1 2008-10-31 17:02:55 sallai Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */

#include "Ds2401.h"

/**
 * HPL for the DS2401 hardware ID chip.
 */
module HplDs2401C {
  provides interface HplDs2401 as Hpl;
  uses interface OneWireMaster as OneWire;
}
implementation {
  bool busy = FALSE;

  async command error_t Hpl.read(ds2401_serial_t* rom) {
    uint8_t i;

    if(busy) {
      return EBUSY;
    }

    busy = TRUE;

    call OneWire.init();

    if(call OneWire.reset() != SUCCESS) {
      call OneWire.release();
      busy = FALSE;
      return EOFF;
    }

    call OneWire.writeByte(0x33);

    for(i=0;i<DS2401_DATA_LENGTH;i++) {
      rom->data[i] = call OneWire.readByte();
    }

    // TODO: crc check

    call OneWire.release();
    busy = FALSE;
    return SUCCESS;
  }
}
