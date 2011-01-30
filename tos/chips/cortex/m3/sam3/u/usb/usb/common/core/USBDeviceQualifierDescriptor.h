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

   Class for manipulating USB device qualifier descriptors.

 !!!Usage

   - Declare a USBDeviceQualifierDescriptor instance as the device qualifier
     descriptor of a USB device.
*/

#ifndef USBDEVICEQUALIFIERDESCRIPTOR_H
#define USBDEVICEQUALIFIERDESCRIPTOR_H

//------------------------------------------------------------------------------
//         Types
//------------------------------------------------------------------------------

#ifdef __ICCARM__          // IAR
#pragma pack(1)            // IAR
#define __attribute__(...) // IAR
#endif                     // IAR

//------------------------------------------------------------------------------
/// Alternate device descriptor indicating the capabilities of the device
/// in full-speed, if currently in high-speed; or in high-speed, if it is
/// currently in full-speed. Only relevant for devices supporting the
/// high-speed mode.
//------------------------------------------------------------------------------
typedef struct {

   /// Size of the descriptor in bytes.
   unsigned char bLength;
   /// Descriptor type (USBDESC_DEVICE_QUALIFIER or "USB device types").
   unsigned char bDescriptorType;
   /// USB specification release number (in BCD format).
   unsigned short bcdUSB;
   /// Device class code.
   unsigned char bDeviceClass;
   /// Device subclass code.
   unsigned char bDeviceSubClass;
   /// Device protocol code.
   unsigned char bDeviceProtocol;
   /// Maximum packet size of endpoint 0.
   unsigned char bMaxPacketSize0;
   /// Number of possible configurations for the device.
   unsigned char bNumConfigurations;
   /// Reserved.
   unsigned char bReserved;         

} __attribute__ ((packed)) USBDeviceQualifierDescriptor; // GCC

#ifdef __ICCARM__          // IAR
#pragma pack()             // IAR
#endif                     // IAR

#endif //#ifndef USBDEVICEQUALIFIERDESCRIPTOR_H

