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
 * Generic configuration for creating a Read interface for a AD converter
 * on the Mulle platform. The Read interface provided will handle the 
 * turning on and off of the VRef pin provided by AVcc.
 *
 * For a example of use see tos/platform/mulle/DemoSensorC.nc.
 *
 * NOTE: The VRef pin can still be handled manually if needed by using
 *       the StdControl provided by AVccClientC.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic configuration AdcReadC(uint8_t channel, uint8_t precision, uint8_t prescaler)
{
  provides interface Read<uint16_t>;

  uses interface GeneralIO as Pin;
}
implementation
{
  components new AdcReadP(channel, precision, prescaler),
      RealMainP, new AdcReadClientC(), new AVccClientC();

  AdcReadP.Pin = Pin;
  AdcReadP.ReadAdc -> AdcReadClientC;
  AdcReadP.AVccControl -> AVccClientC;

  AdcReadClientC.M16c60AdcConfig -> AdcReadP;

  Read = AdcReadP;
}
