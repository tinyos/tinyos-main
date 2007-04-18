/*
 * Copyright (c) 2006 Arched Rock Corporation
 * All rights reserved.
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
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * TestDisseminationAppC exercises the dissemination layer, by causing
 * the node with ID 1 to inject 2 new values into the network every 4
 * seconds. For the 32-bit object with key 0x1234, node 1 toggles LED
 * 0 when it sends, and every other node toggles LED 0 when it
 * receives the correct value. For the 16-bit object with key 0x2345,
 * node 1 toggles LED 1 when it sends, and every other node toggles
 * LED 1 when it receives the correct value.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @author Gilman Tolle <gtolle@archedrock.com>
 * @version $Revision: 1.6 $ $Date: 2007-04-18 04:02:06 $
 */

configuration TestDisseminationAppC {}
implementation {
  components TestDisseminationC;

  components MainC;
  TestDisseminationC.Boot -> MainC;

  components ActiveMessageC;
  TestDisseminationC.RadioControl -> ActiveMessageC;

  components DisseminationC;
  TestDisseminationC.DisseminationControl -> DisseminationC;

  components new DisseminatorC(uint32_t, 0x1234) as Object32C;
  TestDisseminationC.Value32 -> Object32C;
  TestDisseminationC.Update32 -> Object32C;

  components new DisseminatorC(uint16_t, 0x2345) as Object16C;
  TestDisseminationC.Value16 -> Object16C;
  TestDisseminationC.Update16 -> Object16C;

  components LedsC;
  TestDisseminationC.Leds -> LedsC;

  components new TimerMilliC();
  TestDisseminationC.Timer -> TimerMilliC;
}

