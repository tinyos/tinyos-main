/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/
package benchmark.common;

import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class TimerParser {

  private short ios[];
  private long  delay[];
  private long  period[];
  private byte  maxtimer = 0;

  public static final short   DEF_TIMER_ONESHOT = 1;
  public static final short   DEF_TIMER_DELAY   = 0;
  public static final short   DEF_TIMER_PERIOD  = 100;

  public class TimerParserException extends Exception {
    public TimerParserException(String msg) { super(msg); }
  }

  public TimerParser(final byte maxtimercount) {

    this.maxtimer = maxtimercount;

    this.ios = new short[maxtimercount];
    this.delay = new long[maxtimercount];
    this.period = new long[maxtimercount];

    for (int i = 0; i < maxtimercount; ++i) {
      this.ios[i]    = DEF_TIMER_ONESHOT;
      this.delay[i]  = DEF_TIMER_DELAY;
      this.period[i] = DEF_TIMER_PERIOD;
    }
  }

  public void parse(final String spec) throws TimerParserException {

    Pattern pattern = Pattern.compile("(\\d+):(\\d+),(\\d+),(\\d+)");
    Matcher matcher = pattern.matcher(spec);

    if (matcher.find()) {
      int trigidx = Integer.parseInt(matcher.group(1));

      if (trigidx < 1 || trigidx > this.maxtimer) {
        throw new TimerParserException("Valid timer indexes are : [1.." + this.maxtimer + "]!");
      }
      --trigidx;

      this.ios[trigidx] = (byte) Integer.parseInt(matcher.group(2));

      this.delay[trigidx] = Integer.parseInt(matcher.group(3));
      this.period[trigidx] = Integer.parseInt(matcher.group(4));

      if (  this.period[trigidx] < 0 ||
            this.delay[trigidx] < 0 ||
            this.ios[trigidx] < 0 ||
            this.ios[trigidx] > 1) {
        throw new TimerParserException("Trigger timer " + (trigidx + 1) + " is invalid!");
      }

      // at time 0, only one-shot timers are allowed to fire
      if ( this.period[trigidx] == 0 && this.ios[trigidx] != 1) {
        throw new TimerParserException("Only one-shot timers are allowed with 0 ms period!");
      }

    } else {
      throw new TimerParserException("Invalid spec timer specification!");
    }
  }

  public void setSpec(final byte idx,final short ios,final long delay, final long period) {
    this.ios[idx] = ios;
    this.delay[idx] = delay;
    this.period[idx] = period;
  }

  public short[]  getIos()    { return ios;     }
  public long[]   getDelay()  { return delay;   }
  public long[]   getPeriod() { return period;  }
  
}