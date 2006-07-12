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
 * Stanfoard SWIG interface specification for the TOSSIM radio
 * propagation model. This file defines the Radio object that
 * is exported to Python.
 * This particular radio model is gain-based. If you want to change
 * the radio model (and the scripting interface), then you must
 * replace or modify this file and re-run the SWIG interface generation
 * script generate-swig.bash in lib/tossim. Basic TOSSIM includes
 * another model, the binary model, which stores packet loss rates
 * rather than gains.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

%module TOSSIMRadio

%{
#include <radio.h>
%}

class Radio {
 public:
  Radio();
  ~Radio();

  void add(int src, int dest, double gain);
  double gain(int src, int dest);
  bool connected(int src, int dest);
  void remove(int src, int dest);
  void setNoise(int node, double mean, double range);
  void setSensitivity(double sensitivity);   
};

