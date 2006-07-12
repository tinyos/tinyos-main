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

#include <mac.h>
#include <sim_csma.h>

MAC::MAC() {}
MAC::~MAC() {}

int MAC::initHigh() {return sim_csma_init_high();}
int MAC::initLow() {return sim_csma_init_low();}
int MAC::high() {return sim_csma_high();}
int MAC::low() {return sim_csma_low();}
int MAC::symbolsPerSec() {return sim_csma_symbols_per_sec();}
int MAC::bitsPerSymbol() {return sim_csma_bits_per_symbol();}
int MAC::preambleLength() {return sim_csma_preamble_length();}
int MAC::exponentBase() {return sim_csma_exponent_base();}
int MAC::maxIterations() {return sim_csma_max_iterations();}
int MAC::minFreeSamples() {return sim_csma_min_free_samples();}
int MAC::rxtxDelay() {return sim_csma_rxtx_delay();}
int MAC::ackTime() {return sim_csma_ack_time();}

void MAC::setInitHigh(int val) {sim_csma_set_init_high(val);}
void MAC::setInitLow(int val) {sim_csma_set_init_low(val);}
void MAC::setHigh(int val) {sim_csma_set_high(val);}
void MAC::setLow(int val) {sim_csma_set_low(val);}
void MAC::setSymbolsPerSec(int val) {sim_csma_set_symbols_per_sec(val);}
void MAC::setBitsBerSymbol(int val) {sim_csma_set_bits_per_symbol(val);}
void MAC::setPreambleLength(int val) {sim_csma_set_preamble_length(val);}
void MAC::setExponentBase(int val) {sim_csma_set_exponent_base(val);}
void MAC::setMaxIterations(int val) {sim_csma_set_max_iterations(val);}
void MAC::setMinFreeSamples(int val) {sim_csma_set_min_free_samples(val);}
void MAC::setRxtxDelay(int val) {sim_csma_set_rxtx_delay(val);}
void MAC::setAckTime(int val) {sim_csma_set_ack_time(val);}

