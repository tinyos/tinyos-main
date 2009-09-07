/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This file is for the Microcrystal RV-8564 Real-time Clock on the Mulle
 * platform.
 * 
 * @author: Gong Liang
 */

#ifndef __RV8564_H__
#define __RV8564_H__

/* constants */
#define RV8564_WR_ADDR	0xa2  //slave address write 0xa2 or read 0xa3   
#define RV8564_RD_ADDR	0xa3 


#define RV8564_CS1    0x00
#define RV8564_CS2    0x01


/* Control/Status registers */
#define RV8564_CTR1 0x00         //00 Control status 1, 
                                 //Test1 0 Stop 0, Test 0 0 0
								 
#define RV8564_CTR2 0x01         //01 Control status 2,
                                 // 0 x  0 TI/TP, AF TF AIE TIE  
								 // TI/TP=1,INT pulses 
//Note that writing 1 to the alarm flags causes no change...0-1 is not applied.								 
								 
#define RV8564_SEC    0x02          //	
#define RV8564_MIN    0x03          //
#define RV8564_HOUR   0x04          //
#define RV8564_DAY    0x05          //
#define RV8564_WEEK   0x06          //
#define RV8564_MON    0x07          //
#define RV8564_YEAR   0x08          //

#define RV8564_MIN_ALARM    0x09    //
#define RV8564_HR_ALARM     0x0A    //
#define RV8564_DAY_ALARM    0x0B    //
#define RV8564_WK_ALARM     0x0C    //


#define RV8564_CLKF   0x0D       //FE x x x,  x x FD1 FD0
                                 //                0   0    32768 Hz          
                                 //                0   1    61024  Hz                 
                                 //                1   0     32 Hz                           
                                 //                1   1     1  Hz 




#define RV8564_TC     0x0E       //TE x x x,  x x TD1 TD0
                                 //                0   0    4096 Hz          
                                 //                0   1    64   Hz                 
                                 //                1   0     1 Sec                           
                                 //                1   1     1 Min   
								 								                         
#define RV8564_TIMER  0x0F       //128 64  32 16, 8 4 2 1

/*********** Initial setting of the RV_8564ram, Set it before using (debug only) ***********/
uint8_t RV_8564ram[16] = { 0x00, 0x13, 0x01, 0x01,
                           0x01, 0x01, 0x01, 0x01,
                           0x07, 0x80, 0x80, 0x80,
                           0x80, 0x83, 0x83, 1 };


#endif /* __RV8564_H__ */

