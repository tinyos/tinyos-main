/// $Id: M16c62pAdcC.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 *
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "M16c62pAdc.h"

/**
 * HAL for the M16c62p A/D conversion susbsystem.
 *
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

configuration M16c62pAdcC
{
  provides {
    interface Resource[uint8_t client];
    interface M16c62pAdcSingle;
    interface M16c62pAdcMultiple;
  }
  uses interface ResourceConfigure[uint8_t client];
}
implementation
{
  components M16c62pAdcP, HplM16c62pAdcC, PlatformC, MainC,
    new RoundRobinArbiterC(UQ_M16c62pADC_RESOURCE) as AdcArbiter,
    new AsyncStdControlPowerManagerC() as PM;

  Resource = AdcArbiter;
  ResourceConfigure = AdcArbiter;
  M16c62pAdcSingle = M16c62pAdcP;
  M16c62pAdcMultiple = M16c62pAdcP;

  PlatformC.SubInit -> M16c62pAdcP;

  M16c62pAdcP.HplM16c62pAdc -> HplM16c62pAdcC;
  //M16c62pAdcP.M16c62pCalibrate -> PlatformC;

  PM.AsyncStdControl -> M16c62pAdcP;
  PM.ResourceDefaultOwner -> AdcArbiter;
}
