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
 * SWIG interface specification for a media access control algorithm
 * and physical data rate in TOSSIM. This file defines the MAC object
 * which is exported to
 * the python scripting interface. This particular MAC is CSMA.
 * Changing the MAC abstraction requires changing or replacing this
 * file and rerunning generate-swig.bash in lib/tossim. Note that
 * this abstraction does not represent an actual MAC implementation,
 * instead merely a set of configuration constants that a CSMA MAC
 * implementation might use. The default values model the standard
 * TinyOS CC2420 stack. Most times (rxtxDelay, etc.) are in terms
 * of symbols. E.g., an rxTxDelay of 32 means 32 symbol times. This
 * value can be translated into real time with the symbolsPerSec()
 * call.
 *
 * Note that changing this file only changes the Python interface:
 * you must also change the underlying TOSSIM code so Python
 * has the proper functions to call. Look at mac.h, mac.c, and
 * sim_mac.c.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

%module TOSSIMMAC

%{
#include <mac.h>
%}

class MAC {
 public:
  MAC();
  ~MAC();

  int initHigh();
  int initLow();
  int high();
  int low();
  int symbolsPerSec();
  int bitsPerSymbol();
  int preambleLength();
  int exponentBase();
  int maxIterations();
  int minFreeSamples();
  int rxtxDelay();
  int ackTime(); 
  
  void setInitHigh(int val);
  void setInitLow(int val);
  void setHigh(int val);
  void setLow(int val);
  void setSymbolsPerSec(int val);
  void setBitsBerSymbol(int val);
  void setPreambleLength(int val);
  void setExponentBase(int val);
  void setMaxIterations(int val);
  void setMinFreeSamples(int val);
  void setRxtxDelay(int val);
  void setAckTime(int val);
};
