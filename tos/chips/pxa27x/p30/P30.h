/* $Id: P30.h,v 1.4 2006-12-12 18:23:12 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * @author Phil Buonadonna
 */

#ifndef _P30_H
#define _P30_H

#define P30_READ_READARRAY	(0x00FF)
#define P30_READ_RSR		(0x0070)
#define P30_READ_RCR		(0x0090)
#define P30_READ_QUERY		(0x0098)
#define P30_READ_CLRSTATUS	(0x0050)

#define P30_WRITE_WORDPRGSETUP	(0x0040)
#define P30_WRITE_ALTWORDPRGSETUP (0x0010)
#define P30_WRITE_BUFPRG	(0x00E8)
#define P30_WRITE_BUFPRGCONFIRM (0x00D0)
#define P30_WRITE_BEFPSETUP	(0x0080)
#define P30_WRITE_BEFPCONFIRM	(0x00D0)

#define P30_ERASE_BLKSETUP	(0x0020)
#define P30_ERASE_BLKCONFIRM	(0x00D0)

#define P30_SUSPEND_SUSPEND	(0x00B0)
#define P30_SUSPEND_RESUME	(0x00D0)

#define P30_LOCK_SETUP		(0x0060)
#define P30_LOCK_LOCK		(0x0001)
#define P30_LOCK_LOCKDOWN	(0x002F)
#define P30_LOCK_UNLOCK		(0x00D0)

#define P30_PROT_PSRSETUP	(0x00C0)

#define P30_CONFIG_RCRSETUP	(0x0060)
#define P30_CONFIG_RCR		(0x0003)

#define P30_SR_DWS		(1 << 7)
#define P30_SR_ESS		(1 << 6)
#define P30_SR_ES		(1 << 5)
#define P30_SR_PS		(1 << 4)
#define P30_SR_VPPS		(1 << 3)
#define P30_SR_PSS		(1 << 2)
#define P30_SR_BLS		(1 << 1)
#define P30_SR_BWS		(1 << 0)

#define P30_REGION_SIZE (0x100000)
#define P30_BLOCK_SIZE	(0x20000)

typedef struct p30_volume_info_t {
  uint8_t base; // base block
  uint8_t size; // num blocks
} p30_volume_info_t;

#define FLASH_PARTITION_COUNT 16
#define FLASH_PARTITION_SIZE 0x200000
#define FLASH_PROTECTED_REGION 0x00200000
#define FLASH_PROGRAM_BUFFER_SIZE 32
  //#define FLASH_NOT_SUPPORTED 0x100

#endif /* _P30_H */
