/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Wiring for the PXA27X Quick Capture Interface.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - September 10, 2005
 */
 /**                                         
 * Modified and ported to tinyos-2.x.
 * 
 * @author Brano Kusy (branislav.kusy@gmail.com)
 * @version October 25, 2007
 */
 
#include "PXA27XQuickCaptInt.h"

configuration HplPXA27XQuickCaptIntC
{
    provides interface HplPXA27XQuickCaptInt;
}
implementation
{
   components HplPXA27XQuickCaptIntM; 
   HplPXA27XQuickCaptInt = HplPXA27XQuickCaptIntM;
   
   components HplPXA27xInterruptM;
   HplPXA27XQuickCaptIntM.PPID_CIF_Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_CIF];

   components HplPXA27xDMAC;
   HplPXA27XQuickCaptIntM.pxa_dma -> HplPXA27xDMAC.HplPXA27xDMAChnl[CIF_CHAN];

   components dmaArrayC;
   HplPXA27XQuickCaptIntM.dmaArray -> dmaArrayC;

   components GeneralIOC;
   HplPXA27XQuickCaptIntM.LED_PIN -> GeneralIOC.GeneralIO[106];	//A40-29 
	
	 components LedsC;
	 HplPXA27XQuickCaptIntM.Leds -> LedsC;
}
