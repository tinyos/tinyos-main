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
 *
 * Configuration parameters for a CSMA link.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

// $Id: sim_csma.h,v 1.4 2006-12-12 18:23:35 vlahan Exp $

#ifndef SIM_CSMA_H_INCLUDED
#define SIM_CSMA_H_INCLUDED

#ifndef SIM_CSMA_INIT_HIGH
#define SIM_CSMA_INIT_HIGH 400
#endif 

#ifndef SIM_CSMA_INIT_LOW
#define SIM_CSMA_INIT_LOW 20
#endif

#ifndef SIM_CSMA_HIGH
#define SIM_CSMA_HIGH 160
#endif

#ifndef SIM_CSMA_LOW
#define SIM_CSMA_LOW 20
#endif

#ifndef SIM_CSMA_SYMBOLS_PER_SEC
#define SIM_CSMA_SYMBOLS_PER_SEC 65536
#endif

#ifndef SIM_CSMA_BITS_PER_SYMBOL
#define SIM_CSMA_BITS_PER_SYMBOL 4
#endif

#ifndef SIM_CSMA_PREAMBLE_LENGTH
#define SIM_CSMA_PREAMBLE_LENGTH 12
#endif

#ifndef SIM_CSMA_MAX_ITERATIONS
#define SIM_CSMA_MAX_ITERATIONS 0
#endif

#ifndef SIM_CSMA_EXPONENT_BASE
#define SIM_CSMA_EXPONENT_BASE 1
#endif

#ifndef SIM_CSMA_MIN_FREE_SAMPLES
#define SIM_CSMA_MIN_FREE_SAMPLES 2
#endif

// 500 us ~= 32 symbols
#ifndef SIM_CSMA_RXTX_DELAY 
#define SIM_CSMA_RXTX_DELAY 32
#endif

// 12 symbol delay + 11 bytes length * (2 bytes/symbol) = 34 symbols
#ifndef SIM_CSMA_ACK_TIME
#define SIM_CSMA_ACK_TIME 34
#endif

#ifdef __cplusplus
extern "C" {
#endif

  int sim_csma_init_high();
  int sim_csma_init_low();
  int sim_csma_high();
  int sim_csma_low();
  int sim_csma_symbols_per_sec();
  int sim_csma_bits_per_symbol();
  int sim_csma_preamble_length(); // in symbols
  int sim_csma_exponent_base();
  int sim_csma_max_iterations();
  int sim_csma_min_free_samples();
  int sim_csma_rxtx_delay();
  int sim_csma_ack_time(); // in symbols
  
  void sim_csma_set_init_high(int val);
  void sim_csma_set_init_low(int val);
  void sim_csma_set_high(int val);
  void sim_csma_set_low(int val);
  void sim_csma_set_symbols_per_sec(int val);
  void sim_csma_set_bits_per_symbol(int val);
  void sim_csma_set_preamble_length(int val); // in symbols
  void sim_csma_set_exponent_base(int val);
  void sim_csma_set_max_iterations(int val);
  void sim_csma_set_min_free_samples(int val);
  void sim_csma_set_rxtx_delay(int val);
  void sim_csma_set_ack_time(int val); // in symbols
  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_TOSSIM_H_INCLUDED
