/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met: 
 * 
 * - Redistributions of source code must retain the above copyright 
 *   notice, this list of conditions and the following disclaimer. 
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the 
 *   distribution. 
 * - Neither the name of the copyright holders nor the names of 
 *   its contributors may be used to endorse or promote products derived 
 *   from this software without specific prior written permission. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL 
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

/**
 * High Speed Multimedia Card Interface Configurations.
 *
 * @author JeongGil Ko
 * @author Kevin Klues
 */

#include <sam3uhsmcihardware.h>

configuration Sam3uHsmciC {
  provides {
    interface Sam3uHsmciInit @exactlyonce();
    interface Resource[uint8_t];
    interface Sam3uHsmci[uint8_t];
  }
}
implementation {
  components Sam3uHsmciP;
  Sam3uHsmciInit = Sam3uHsmciP;
  Sam3uHsmci = Sam3uHsmciP;
  
  components HplSam3uHsmciC;
  Sam3uHsmciP.HplSam3uHsmci -> HplSam3uHsmciC;
  Sam3uHsmciP.ArbiterInfo -> FcfsArbiterC;

  components new FcfsArbiterC(SAM3U_HSMCI_RESOURCE);
  components new AsyncStdControlPowerManagerC() as PM;
  Resource = FcfsArbiterC;
  PM.ResourceDefaultOwner -> FcfsArbiterC;
  PM.ArbiterInfo -> FcfsArbiterC;
  PM.AsyncStdControl -> HplSam3uHsmciC;

  components LedsC;
  Sam3uHsmciP.Leds -> LedsC;
}
