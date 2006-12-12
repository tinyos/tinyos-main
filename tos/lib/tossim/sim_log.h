/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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

// $Id: sim_log.h,v 1.4 2006-12-12 18:23:35 vlahan Exp $


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
