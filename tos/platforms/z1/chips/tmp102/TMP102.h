/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Types and definitions for the TI TMP175
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:14 $
 */

#ifndef _TMP102_H
#define _TMP102_H

#define TMP102_SLAVE_ADDR (0x48)

#define TMP102_PTR_TEMP		(0x0)
#define TMP102_PTR_CFG		(0x1)
#define TMP102_PTR_TLOW		(0x2)
#define TMP102_PTR_THIGH	(0x3)

#define TMP102_CFG_OS		((1 << 7) << 8)
#define TMP102_CFG_RES(_x)	((((_x) & 0x3) << 5) << 8)
#define TMP102_CFG_FQ(_x)	((((_x) & 0x3) << 3) << 8)
#define TMP102_CFG_POL		((1 << 2) << 8)
#define TMP102_CFG_TM		((1 << 1) << 8)
#define TMP102_CFG_SD		((1 << 0) << 8)

#define TMP102_CFG_CR(_x) (((_x) & 0x3) << 6)
#define TMP102_CFG_AL (1 << 5)
#define TMP102_CFG_EM (1 << 4)


typedef enum {
  TMP102_FQD_1 = 0,
  TMP102_FQD_2 = 1,
  TMP102_FQD_4 = 2,
  TMP102_FQD_6 = 3
} tmp102_fqd_t;

typedef enum {
  TMP102_CR_025HZ,
  TMP102_RES_1HZ,
  TMP102_RES_4HZ,
  TMP102_RES_8HZ
} tmp102_cr_t;



#endif /* _TMP102_H */
