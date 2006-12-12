//$Id: msp430baudrates.h,v 1.3 2006-12-12 18:23:11 vlahan Exp $
//@author Vlado Handziski <handzisk@tkn.tu-berlin.de>

#ifndef _H_msp430baudrates_h
#define _H_msp430baudrates_h

/**
Parameters for HPLUSARTControl.setClockRate() that generate some standard baud rates.
Usage is setClockRate(UBR_CLOCK_BAUDRATE, UMCTL_CLOCK_BAUDRATE), see HPLUARTM.nc for an example.

The calculations were performed using the msp-uart.pl script:
# msp-uart.pl -- calculates the uart registers for MSP430
#
# Copyright (C) 2002 - Pedro Zorzenon Neto - pzn dot debian dot org


**/


enum {
//Using ACLK=32768Hz
UBR_ACLK_1200=0x001B,    UMCTL_ACLK_1200=0x94,
UBR_ACLK_1800=0x0012,    UMCTL_ACLK_1800=0x84,
UBR_ACLK_2400=0x000D,    UMCTL_ACLK_2400=0x6D,
UBR_ACLK_4800=0x0006,    UMCTL_ACLK_4800=0x77,
UBR_ACLK_9600=0x0003,    UMCTL_ACLK_9600=0x29,

//Using SMCLK=1048576Hz
UBR_SMCLK_1200=0x0369,   UMCTL_SMCLK_1200=0x7B,
UBR_SMCLK_1800=0x0246,   UMCTL_SMCLK_1800=0x55,
UBR_SMCLK_2400=0x01B4,   UMCTL_SMCLK_2400=0xDF,
UBR_SMCLK_4800=0x00DA,   UMCTL_SMCLK_4800=0xAA,
UBR_SMCLK_9600=0x006D,   UMCTL_SMCLK_9600=0x44,
UBR_SMCLK_19200=0x0036,  UMCTL_SMCLK_19200=0xB5,
UBR_SMCLK_38400=0x001B,  UMCTL_SMCLK_38400=0x94,
UBR_SMCLK_57600=0x0012,  UMCTL_SMCLK_57600=0x84,
UBR_SMCLK_76800=0x000D,  UMCTL_SMCLK_76800=0x6D,
UBR_SMCLK_115200=0x0009, UMCTL_SMCLK_115200=0x10,
UBR_SMCLK_230400=0x0004, UMCTL_SMCLK_230400=0x55,
};


#endif//_H_msp430baudrates_h
