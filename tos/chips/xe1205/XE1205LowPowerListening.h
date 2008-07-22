/* Copyright (c) 2007 Shockfish SA
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Maxime Muller
 *
 */

#ifndef XE1205LOWPOWERLISTENING_H
#define XE1205LOWPOWERLISTENING_H

/**
 * Amount of time, in milliseconds, to keep the radio on after
 * a successful receive addressed to this node
 */

#ifndef DELAY_AFTER_RECEIVE
#define DELAY_AFTER_RECEIVE 20
#endif

/**
 * Value used to indicate the message being sent should be transmitted
 * one time
 */

#ifndef ONE_MESSAGE
#define ONE_MESSAGE 0
#endif

#ifndef DEFAULT_DUTY_PERIOD
#define DEFAULT_DUTY_PERIOD 80
#endif


enum { 
    IDLE = 0,
    RX = 1,
};

#endif
