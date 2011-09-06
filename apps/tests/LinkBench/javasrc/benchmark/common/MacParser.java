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

public class MacParser {

  private int macparams[];
  private short flags;

  public class MacParserException extends Exception {
    public MacParserException(String msg) { super(msg); }
  }

  public MacParser() {
    this.macparams = new int[BenchmarkStatic.MAC_SETUP_LENGTH];
    this.flags = 0;
    for (int i = 0; i < BenchmarkStatic.MAC_SETUP_LENGTH; ++i) {
      this.macparams[i] = 0;
    }
  }

  public void parse(final String spec) throws MacParserException {

    Pattern pattern = Pattern.compile("^(\\w+):([\\d+,]+)$");
    Matcher matcher = pattern.matcher(spec);
    
    if (matcher.find()) {
      this.parseAll(matcher.group(1),matcher.group(2).split(","));

    } else {
      throw new MacParserException("Invalid MAC parameter specification, see help!");
    }
  }

  public void parseAll(final String type, final String[] params) throws MacParserException {
    int[] iparams = new int[params.length];
    for(byte i=0; i< params.length; ++i)
      iparams[i] = Integer.parseInt(params[i]);

    this.parseAll(type, iparams);
  }

  public void parseAll(final String type, final int[] params) throws MacParserException {
    this.parseLPL(type, params);
    this.parsePacketLink(type, params);

    if ( (this.flags & (this.flags - 1)) != 0)
      throw new MacParserException("Only one MAC protocol is allowed!");

  }

  public static String macAsString(final short flags, final int[] params) {
    String nl = System.getProperty("line.separator");

    return  LPLasString(flags,params) + nl +
            PacketLinkasString(flags,params) + nl;           
  }

  public static String macAsXml(final short flags, final int[] params) {
    String nl = System.getProperty("line.separator");

    return "<mac>" +
            LPLasXml(flags,params) + 
            PacketLinkasXml(flags,params) +
            "</mac>" + nl;
  }

  private void parseLPL(final String type, final int[] params) throws MacParserException {
    if ( type.equals("lpl") ) {
      if (params.length != 1) {
        throw new MacParserException(
                "LPL MAC requires exactly one parameter ( Wakeup interval (ms) )!");
      }
      flags |= BenchmarkStatic.GLOBAL_USE_MAC_LPL;
      this.macparams[BenchmarkStatic.LPL_WAKEUP_OFFSET] = params[0];
    }
  }

  private static String LPLasString(final short flags, final int[] params) {
    String ret="";
    if ((flags & BenchmarkStatic.GLOBAL_USE_MAC_LPL) != 0) {
      ret = "  LPL: \t\t" + params[0] + " ms";
    }
    return ret;
  }
  
  private static String LPLasXml(final short flags, final int[] params) {
    String ret="";
    if ((flags & BenchmarkStatic.GLOBAL_USE_MAC_LPL) != 0) {
      ret = "<lpl wakeup=\"" + params[0] + "\"/>";
    }
    return ret;
  }

  private void parsePacketLink(final String type, final int[] params) throws MacParserException {
    if ( type.equals("plink") ) {
      if (params.length != 2) {
        throw new MacParserException(
                "Packet Link MAC requires exactly two parameters ( Retries (ms) + Delay (ms) )!");
      }
      flags |= BenchmarkStatic.GLOBAL_USE_MAC_PLINK;
      this.macparams[BenchmarkStatic.PLINK_RETRIES_OFFSET] = params[0];
      this.macparams[BenchmarkStatic.PLINK_DELAY_OFFSET] = params[1];
    }
  }

  private static String PacketLinkasString(final short flags, final int[] params) {
    String ret="";
    if ((flags & BenchmarkStatic.GLOBAL_USE_MAC_PLINK) != 0) {
      ret = "  Packet Link:  Retries: " + params[0] + " ms, Delay: " + params[0] + " ms";
    }
    return ret;
  }

  private static String PacketLinkasXml(final short flags, final int[] params) {
    String ret="";
    if ((flags & BenchmarkStatic.GLOBAL_USE_MAC_PLINK) != 0) {
      ret = "<plink retries=\"" + params[0] + "\" delay=\"" + params[1] + "\"/>";
    }
    return ret;
  }


  public int[]  getMacParams()    { return macparams;     }
  public short  getFlags()        { return flags;         }

}