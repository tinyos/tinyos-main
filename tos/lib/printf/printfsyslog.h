/*
 * Copyright (c) 2014 Martin Cerveny
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
 * Local (per file) conditional printing macros (facility+level filtering like syslog)
 *
 * In each file:
 * 1) choose unique file tag "TAG"
 * 2) define facilities
 *     #define TAG_F1_FACILITY (1<<0)
 *     #define TAG_F2_FACILITY (1<<1)
 *     #define TAG_F3_FACILITY (1<<2) ...
 * 3) define facilities name
 *     #define TAG_F1_NAME "F1"
 *     #define TAG_F2_NAME "F2"
 *     #define TAG_F3_NAME "F3" ...
 * 4) define severity filter per facility
 *     #define TAG_F1_SEVERITY LOG_WARNING
 *     #define TAG_F2_SEVERITY LOG_CRITICAL
 *     #define TAG_F3_SEVERITY LOG_ERROR ...
 * 5) define facility filter mask
 *     #define TAG_FACILITY_MASK (TAG_F1_FACILITY | TAG_F2_FACILITY)
 * 6) log message with  prinfsyslog/prinfsyslog_inline/prinfsyslog_flush
 *      for "source" use TAG
 *      for "facility" use TAG_F1
 *      for "priority" use LOG_WARNING (defined below)
 * 7) optionally define macro preprocess
 *     #define TAG_W(facility, ...) prinfsyslog(TAG, TAG_ ## facility, LOG_WARNING, __VA_ARGS__)
 *     #define TAG_W_inline(facility, ...) prinfsyslog_inline(TAG, TAG_ ## facility, LOG_WARNING, __VA_ARGS__)
 *     #define TAG_W_flush(facility) prinfsyslog_flush(TAG, TAG_ ## facility, LOG_WARNING)
 *     #define TAG_N(facility, ...) prinfsyslog(TAG, TAG_ ## facility, LOG_NOTICE, __VA_ARGS__)
 *     #define TAG_I(facility, ...) prinfsyslog(TAG, TAG_ ## facility, LOG_INFO, __VA_ARGS__)
 * 8) use macros
 *      TAG_W(TAG_F1, "some standalone string %s\n", svariable);
 *      TAG_W(TAG_F1, "some string %s and more", svariable);
 *      TAG_W_inline(TAG_F1, "-- more %s --", svariable);
 *      TAG_W_inline(TAG_F1, "-- last %s\n", svariable);
 *      TAG_W_flush(TAG_F1);
 *
 * define "PRINTFSYSLOG" in makefile to global enable this feature
 * define "PRINTFSYSLOG_LINE" in makefile to include source line number in meta-information too
 *
 *  @author Martin Cerveny
 */

#ifndef PRINTFSYSLOG_H
#define PRINTFSYSLOG_H

// Priorities (these are ordered)

#define LOG_EMERG 0 /* system is unusable */
#define LOG_ALERT 1 /* action must be taken immediately */
#define LOG_CRIT 2 /* critical conditions */
#define LOG_ERR 3 /* error conditions */
#define LOG_WARNING 4 /* warning conditions */
#define LOG_NOTICE 5 /* normal but significant condition */
#define LOG_INFO 6 /* informational */
#define LOG_DEBUG 7 /* debug-level messages */

#define LOG_EMERG_NAME "M"
#define LOG_ALERT_NAME "A"
#define LOG_CRIT_NAME "C"
#define LOG_ERR_NAME "E"
#define LOG_WARNING_NAME "W"
#define LOG_NOTICE_NAME "N"
#define LOG_INFO_NAME "I"
#define LOG_DEBUG_NAME "D"

// if enabled "PRINTFSYSLOG" define macros

#ifdef PRINTFSYSLOG

// if enabled "PRINTFSYSLOG_LINE" prepare line number output

#ifdef PRINTFSYSLOG_LINE
// double expansion trick
#define _PRINTFSYSLOG_STR_(x) #x
#define _PRINTFSYSLOG_STR(x) _PRINTFSYSLOG_STR_(x)
#define _PRINTFSYSLOG_LINE "/" _PRINTFSYSLOG_STR(__LINE__)
#else
#define _PRINTFSYSLOG_LINE
#endif

// include tinyos printf
#define NEW_PRINTF_SEMANTICS 1
#include "printf.h"

// store format string in PGM memory and copy to ram before printf
// TODO: tinyos printf should be rewritten like printf_P in <stdio.h>
// TODO: tested only on AVR platform (PSTR(), strncpy_P())

char _printf_format[128];
char * copyram(PGM_P ptr) {
	return strncpy_P(_printf_format, ptr, sizeof(_printf_format));
}

/**
 * Printf debugging information (formated parameters) prefixed with meta-information (TAG/FACILITY/LEVEL[/LINE])
 * if matched with mask and priority is equal and higher than defined severity
 *
 * @param source TAG (printed as string)
 * @param facility Facility, must be defined like TAG_F1_FACILITY (TAG_F1_NAME printed as string).
 * @param priority Priority level, defined LOG_* (LOG_*_NAME printed as string)
 * @param format "printf" format string
 * @param ... data (va_args) for format string
 */
	
#define prinfsyslog(source, facility, priority, format, ...) ((((facility ## _FACILITY) & (source ## _FACILITY_MASK)) && (priority <= ((facility ## _SEVERITY)))) \
? printf(copyram(PSTR(#source "/" facility ## _NAME "/" priority ## _NAME _PRINTFSYSLOG_LINE ": " format)), ##__VA_ARGS__) : (void)0)

/**
 * Printf debugging information (formated parameters) without prefix (for inline multidata printing)
 * if matched with mask and priority is equal and higher than defined severity
 *
 * @param source TAG (not printed)
 * @param facility Facility, must be defined like TAG_F1_FACILITY (not printed).
 * @param priority Priority level, defined LOG_* (not printed)
 * @param format "printf" format string
 * @param ... data (va_args) for format string
 */

#define prinfsyslog_inline(source, facility, priority, format, ...) ((((facility ## _FACILITY) & (source ## _FACILITY_MASK)) && (priority <= ((facility ## _SEVERITY)))) \
? printf(copyram(PSTR(format)), ##__VA_ARGS__) : (void)0)

/**
 * Printfflush debugging information
 * if matched with mask and priority is equal and higher than defined severity
 *
 * @param source TAG (not printed)
 * @param facility Facility, must be defined like TAG_F1_FACILITY (not printed).
 * @param priority Priority level, defined LOG_* (not printed)
 */

#define prinfsyslog_flush(source, facility, priority) ((((facility ## _FACILITY) & (source ## _FACILITY_MASK)) && (priority <= ((facility ## _SEVERITY)))) \
? printfflush() : (void)0)

#else

// disable all printfsyslog

#define prinfsyslog(...)
#define prinfsyslog_inline(...)
#define prinfsyslog_flush(...)

#endif /* PRINTFSYSLOG */

#endif /* PRINTFSYSLOG_H */
