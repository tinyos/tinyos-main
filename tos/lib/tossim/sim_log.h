/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 * The TOSSIM logging system. Unlike in TinyOS 1.x, this logging
 * system supports an arbitrary number of channels, denoted by
 * a string identifier. A channel can be connected to any number
 * of outputs, and a debug statement can be associated with any
 * number of channels.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: sim_log.h,v 1.5 2010-06-29 22:07:51 scipio Exp $


#ifndef SIM_LOG_H_INCLUDED
#define SIM_LOG_H_INCLUDED

#ifndef TOSSIM_NO_DEBUG
#define dbg(s, ...) sim_log_debug(unique("TOSSIM.debug"), s, __VA_ARGS__)
#define dbg_clear(s, ...) sim_log_debug_clear(unique("TOSSIM.debug"), s, __VA_ARGS__)
#define dbgerror(s, ...) sim_log_error(unique("TOSSIM.debug"), s, __VA_ARGS__)
#define dbgerror_clear(s, ...) sim_log_error_clear(unique("TOSSIM.debug"), s, __VA_ARGS__)
#else
#define dbg(s, ...)
#define dbg_clear(s, ...)
#define dbgerror(s, ...)
#define dbgerror_clear(s, ...)
#endif

#ifdef __cplusplus
extern "C" {
#endif

void sim_log_init();
void sim_log_add_channel(char* output, FILE* file);
bool sim_log_remove_channel(char* output, FILE* file);
void sim_log_commit_change();

void sim_log_debug(uint16_t id, char* string, const char* format, ...);
void sim_log_error(uint16_t id, char* string, const char* format, ...);
void sim_log_debug_clear(uint16_t id, char* string, const char* format, ...);
void sim_log_error_clear(uint16_t id, char* string, const char* format, ...);

#ifdef __cplusplus
}
#endif
  
#endif // SIM_LOG_H_INCLUDED
