/*
 * Copyright (c) 2007 Toilers Research Group - Colorado School of Mines
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
 * - Neither the name of Toilers Research Group - Colorado School of 
 *   Mines  nor the names of its contributors may be used to endorse 
 *   or promote products derived from this software without specific
 *   prior written permission.
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
 * Author: Chad Metcalf
 * Date: Oct 1, 2007
 *
 * A simple TOSSIM driver for the TestSerial application that utilizes 
 * TOSSIM Live extensions.
 *
 */

#include <stdio.h>
#include <tossim.h>
#include <SerialForwarder.h>
#include <Throttle.h>
#include <radio.h>
#include <math.h>
#include <unistd.h>

int main() {
 Tossim* t = new Tossim(NULL);
 t-> init();

 Throttle throttle(t, 10);
 SerialForwarder sf(9001);

 for (int i = 0; i < 1; i++) {
   Mote* m = t->getNode(i);
   m->bootAtTime(rand() % t->ticksPerSecond());
 }


 t->addChannel("Serial", stdout);
 t->addChannel("TestSerialC", stdout);
 t->addChannel("Atm128AlarmC", stdout);

 Radio* r = t->radio();
 for (int i = 0; i < 1; i++) {
    r->setNoise(i, -105.0, 1.0);
   for (int j = 0; j < 1; j++) {
      r->add(i, j, -96.0 - (double)abs(i - j));
      r->add(j, i, -96.0 - (double)abs(i - j));
   }
 }

sf.process();

 throttle.initialize();
 while(t->time() < 600 * t->ticksPerSecond()) {
   throttle.checkThrottle();
   sf.process();
   t->runNextEvent();
 }
}
