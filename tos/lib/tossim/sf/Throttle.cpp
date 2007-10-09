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
 * Date: July 9, 2007
 *
 * A simple Throttle to slow a simulation to near real time.
 *
 */

#include "Throttle.h"

Throttle::Throttle(Tossim* tossim, const int ms = 10) : 
    sim(tossim), simStartTime(0.0), simEndTime(0.0), simPace(0), throttleCount(0) {

        // Convert milliseconds to sim_time_t 
        simPace =  ms * 10000000ULL;
}

Throttle::~Throttle() {}

void Throttle::initialize() {
    simStartTime = getTime();
}

void Throttle::finalize() {
    simEndTime = getTime();
}

void Throttle::checkThrottle() {
    
    double secondsElasped = getTime() - simStartTime;
    sim_time_t ticksElasped = (sim_time_t) secondsElasped*sim->ticksPerSecond();

    sim_time_t difference = sim->time() - ticksElasped;

    if (difference > simPace) {
        throttleCount++;
        double sleepDifference = (double) difference / sim->ticksPerSecond();
        simSleep(sleepDifference);
    }

}

inline double Throttle::toDouble(struct timeval* tv) {
    return tv->tv_sec + tv->tv_usec/1e6;
}

double Throttle::getTime() {
    struct timeval tv;
    gettimeofday (&tv, NULL);
    return toDouble(&tv);  
}

int Throttle::simSleep(double seconds) {

     struct timespec tv;
     /* Construct the timespec from the number of whole seconds... */
     tv.tv_sec = (time_t) seconds;
     /* ... and the remainder in nanoseconds. */
     tv.tv_nsec = (long) ((seconds - tv.tv_sec) * 1e+9);

     while (1)
     {
         /* Sleep for the time specified in tv. If interrupted by a
         signal, place the remaining time left to sleep back into tv. */
         int rval = nanosleep (&tv, &tv);

         if (rval == 0)
             /* Completed the entire sleep time; all done. */
             return 0;
         else if (errno == EINTR)
             /* Interrupted by a signal. Try again. */
             continue;
         else 
             /* Some other error; bail out. */
             return rval;
     }

     return 0;
}

void Throttle::printStatistics() {

    printf("Number of throttle events %d\n", throttleCount);

    if (simEndTime > 0.0) {
        printf("Total Sim Time: %.6f\n", simEndTime - simStartTime);
    }

}
