/*
 * Copyright (c) 2011, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Zsolt Szabo
 */

#ifndef BH1750FVI_H
#define BH1750FVI_H

enum {
  POWER_DOWN	=	0x00,
  POWER_ON	=	0x01,
  RESET         =       0x07,
  CONT_H_RES    =       0x10,
  CONT_H2_RES   =       0x11,
  CONT_L_RES    =       0x13,
  ONE_SHOT_H_RES        =       0x20,
  ONE_SHOT_H2_RES       =       0x21,
  ONE_SHOT_L_RES        =       0x23,
} bh1750fviCommand;

enum {
  TIMEOUT_H_RES =       180, // max 180
  TIMEOUT_H2_RES=       180, // max 180
  TIMEOUT_L_RES =        16, // max 24
} bh1750fviTimeout;

enum {
  WRITE_ADDRESS =       0x23,//0x46,  //if addr== H then it would be 0xb8
  READ_ADDRESS  =       0x23,//0x47,  //                             0xb9     
} bh1750fviHeader;

#endif
