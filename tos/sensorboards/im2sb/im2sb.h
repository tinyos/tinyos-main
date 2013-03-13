/* $Id: im2sb.h,v 1.5 2008-06-11 00:42:14 razvanm Exp $ */
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
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * Revision: $Revision: 1.5 $
 *
 */

#ifndef _IM2SB_H
#define _IM2SB_H

#define GPIO_SHT11_DATA			(100)
#define GPIO_SHT11_CLK			(98)

#define GPIO_TSL2561_LIGHT_INT		(99)
#define GPIO_MAX1363_ANALOG_INT		(99)

#define GPIO_LIS3L02DQ_RDY_INT		(96)
#define GPIO_TMP175_TEMP_ALERT		(96)

#define GPIO_PWR_ADC_NSHDWN		(93)

#define TSL2561_SLAVE_ADDR (0x49)
#define TMP175_SLAVE_ADDR (0x4A) //(0x48)
#define MAX136_SLAVE_ADDR (0x34)

#endif /* _IM2SB_H */
