/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * ----------------------------------------------------------------------------
 */

/**
 \unit

 !!!Purpose

 Definition of the USB descriptors required by a CDC device serial
 driver.
*/

#ifndef CDCDSERIALDRIVERDESCRIPTORS_H
#define CDCDSERIALDRIVERDESCRIPTORS_H

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include <usb/device/core/USBDDriverDescriptors.h>

//------------------------------------------------------------------------------
//         Definitions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "CDC Serial Endpoints"
/// This page lists the endpoints used in CDC Serial Device.
///
/// !Endpoints
/// - CDCDSerialDriverDescriptors_DATAOUT
/// - CDCDSerialDriverDescriptors_DATAIN
/// - CDCDSerialDriverDescriptors_NOTIFICATION

/// Data OUT endpoint number.
#define CDCDSerialDriverDescriptors_DATAOUT             1
/// Data IN endpoint number.
#define CDCDSerialDriverDescriptors_DATAIN              2
/// Notification endpoint number.
#define CDCDSerialDriverDescriptors_NOTIFICATION        3
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//         Exported variables
//------------------------------------------------------------------------------

/// List of descriptors for a CDC device serial driver.
extern USBDDriverDescriptors cdcdSerialDriverDescriptors;

#endif //#ifndef CDCDDRIVERDESCRIPTORS_H

