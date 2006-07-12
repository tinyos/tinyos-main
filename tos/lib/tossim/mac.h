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

#ifndef MAC_H_INCLUDED
#define MAC_H_INCLUDED

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
  int preambleLength(); // in symbols
  int exponentBase();
  int maxIterations();
  int minFreeSamples();
  int rxtxDelay();
  int ackTime(); // in symbols
  
  void setInitHigh(int val);
  void setInitLow(int val);
  void setHigh(int val);
  void setLow(int val);
  void setSymbolsPerSec(int val);
  void setBitsBerSymbol(int val);
  void setPreambleLength(int val); // in symbols
  void setExponentBase(int val);
  void setMaxIterations(int val);
  void setMinFreeSamples(int val);
  void setRxtxDelay(int val);
  void setAckTime(int val); // in symbols int 
};

#endif
