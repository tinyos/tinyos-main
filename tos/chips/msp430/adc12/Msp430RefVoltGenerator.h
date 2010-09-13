/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.5 $
 * $Date: 2007-03-14 18:14:06 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef REFVOLTGENERATOR_H
#define REFVOLTGENERATOR_H

// Time for generator to become stable (in ms) - don't change.
#define MSP430_REFVOLT_STABILIZE_INTERVAL 17

// Delay before generator is actually switched off after it has been stopped 
// (in ms). This avoids having to wait another 17 ms in case the generator is
// needed again shortly after it has been stopped.
#ifndef MSP430_REFVOLT_SWITCHOFF_INTERVAL
#define MSP430_REFVOLT_SWITCHOFF_INTERVAL 20
#endif


// The two values below depend on the external capacitor CVREF+ (cf. msp430fxxx 
// datasheet). The values have been measured on the tinynode platform, which
// applies the TI's reference design (platforms that don't follow this design
// may want to update the values).

// Time (in ms) for reference voltage to drop from 2.5v to 1.5v
#ifndef MSP430_REFVOLT_SWITCH_2_5_TO_1_5_INTERVAL
#define MSP430_REFVOLT_SWITCH_2_5_TO_1_5_INTERVAL 70
#endif

// Time (in ms) for reference voltage to drop from 2.5v to 1.5v after being disabled
#ifndef MSP430_REFVOLT_DROP_2_5_TO_1_5_INTERVAL
#define MSP430_REFVOLT_DROP_2_5_TO_1_5_INTERVAL 2048
#endif

#endif
