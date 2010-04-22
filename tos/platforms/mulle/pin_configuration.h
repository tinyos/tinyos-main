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
 * Inactive pin states on Mulle.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#ifndef __PIN_CONFIGURATION_H__
#define __PIN_CONFIGURATION_H__

//P00/D0/AN10
//P01/D1/AN11
//P02/D2/AN12
//P03/D3/AN13
//P04/D4/AN14
//P05/D5/AN15
//P06/D6/AN16
//P07/D7/AN17 - Radio.SLP_TR
#define PORT_P0_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)

//P10/D8	RADIO.MISO (INPUT)
//P11/D9	RADIO.MOSI
//P12/D10	Accel.SLEEP_MODE
//P13/D11
//P14/D12
//P15/D13/INT3
//P16/D14/INT4
//P17/D15/INT5
#define PORT_P1_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)

#define PORT_P2_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)

//P30       Accel.GS1
//P31       Accel.GS2  
//P32/A10	Flash.EN
//P33/A11	Radio.SCLK
//P34/A12	Ext. LED
//P35/A13	Radio.SEL (HIGH)
//P36/A14	Red LED
//P37/A14	Green LED                                                   
#define PORT_P3_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_HIGH,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)
     
//P40/A16	Flash.SO
//P41/A17	Flash.SI
//P42/A18	Flash.SCK
//P43/A19	Radio.RST (HIGH)
//P44/CS0	Flash.WP
//P45/CS1	Flash.CS
//P46/CS2	Flash.RESET
//P47/CS3	RTC.CLKOE
#define PORT_P4_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)

#define PORT_P5_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)


//P62/RXD0	UART0.TXD
//P63/TXD0	UART0.RXD
//P66/RXD1	UART1.TXD
//P67/TXD1	UART1.RXD
#define PORT_P6_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)

//P70/TXD2/SDA2	UART2.TXD
//P71/RDX2/SCK2	UART2.TXD
//P72/TA1OUT
//P74/TA2OUT
//P75	Vcc for I2C (must be pulled high before the I2C bus can be used)
//P76	Accel VCC
//P77	Radio VCC (HIGH)
#define PORT_P7_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW)


//P80/TA4OUT	H1.47 ; IC1.P97/ADTRG
//P81/TA4IN
//P82/INT0	RTC.CLKOUT
//P83/INT1	RADIO.IRQ (INPUT)
//P84/INT2	RTC.INT
//P85/NMI	pulled high through resistor
//P87/XCIN	RTC.CLKOUT
#define PORT_P8_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT)

//P90/TB0IN	RTC.CLKOUT
//P91
//P92/TB2IN	RTC.CLKOUT
//P93/DA0/TB3IN
//P94/DA1/TB4IN
//P95/ANEX0
//P96/ANEX1
//P97/ADTRG
#define PORT_P9_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                        M16C_PIN_INACTIVE_INPUT)

//P100/AN00
//P101/AN01
//P102/AN02
//P103/AN03 - Accel.Z
//P104/AN04 - Accel.Y
//P105/AN05 - Accel.X
//P106/AN06
//P107/AN07
#define PORT_P_10_INACTIVE_STATE M16C_PORT_INACTIVE_STATE(M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW,\
                                                          M16C_PIN_INACTIVE_OUTPUT_LOW)






#endif //__PIN_CONFIGURATION_H__
