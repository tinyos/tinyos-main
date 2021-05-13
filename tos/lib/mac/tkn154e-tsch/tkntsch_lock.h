/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 *
 * ========================================================================
 */

#ifndef TKNTSCH_LOCK_H_
#define TKNTSCH_LOCK_H_

typedef uint8_t tkntsch_lock_t;
enum {
  TKNTSCH_LOCK_FREE,
  TKNTSCH_LOCK_LOCKED
} tkntsch_lock_state_e;

#define TKNTSCH_TEST_LOCKED(lock, result) atomic{ ((result) = ((lock) == TKNTSCH_LOCK_LOCKED) ? TRUE : FALSE); }
#define TKNTSCH_ACQUIRE_LOCK(lock, result) atomic{ if ((lock) == TKNTSCH_LOCK_LOCKED) { (result) = FALSE; } \
    else { (lock) = TKNTSCH_LOCK_LOCKED; (result) = TRUE; } }
#define TKNTSCH_RELEASE_LOCK(lock) atomic{ (lock) = TKNTSCH_LOCK_FREE; }

#endif /* TKNTSCH_LOCK_H_ */

