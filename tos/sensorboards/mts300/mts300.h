/* $Id: mts300.h,v 1.3 2007-03-14 03:25:06 pipeng Exp $ */
/*
 * Copyright (c) 2005-2006 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */
/**
 * 
 * @author Hu Siquan <husq@xbow.com>
 * Revision: $Revision: 1.3 $
 *
 */

#ifndef _MTS300_H
#define _MTS300_H

// sounder enable (1) /disable (0)
#ifndef SOUNDER
#define SOUNDER 1
#endif

#define UQ_ACCEL_RESOURCE "mts300.accel"
#define UQ_PHOTO_RESOURCE "mts300.photo"
#define UQ_TEMP_RESOURCE "mts300.temp"
#define UQ_PHOTOTEMP_RESOURCE "mts300.phototemp"
#define UQ_MIC_RESOURCE "mts300.microphone"
#define UQ_MAG_RESOURCE "mts300.mag"

enum
{
  TOS_MIC_POT_ADDR = 0x5A,
  TOS_MAG_POT_ADDR = 0x58,
};

// debug leds
//#define _DEBUG_LEDS
#ifdef _DEBUG_LEDS
#define DEBUG_LEDS(X)         X.DebugLeds -> LedsC
#else
#define DEBUG_LEDS(X)         X.DebugLeds -> NoLedsC
#endif
#endif /* _MTS300_H */

