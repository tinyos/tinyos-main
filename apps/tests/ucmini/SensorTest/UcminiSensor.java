/*
* Copyright (c) 2011, University of Szeged
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
* Author: Andras Biro
*/ 

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class UcminiSensor implements MessageListener {

  private MoteIF moteIF;
  private long calibration[]=new long[6];
  public UcminiSensor(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new UcminiSensorMeas(), this);
  }

  public void messageReceived(int to, Message message) {
    if(message instanceof UcminiSensorMeas){
      UcminiSensorMeas msg = (UcminiSensorMeas)message;
      System.out.format("Humidity (sht21):\t\t%8.3f %% \t(%d)\n", (double)msg.get_humi()/100, msg.get_humi());
      System.out.format("Temperature (sht21):\t\t%8.3f \u00B0C \t(%d)\n", (double)msg.get_temp_sht21()/100, msg.get_temp_sht21());
      System.out.format("Temperature (atmega128rfa1):\t%8.3f \u00B0C \t(%d)\n", (double)msg.get_temp_atmel()/100, msg.get_temp_atmel());
      System.out.format("Temperature (ms5607):\t\t%8.3f \u00B0C \t(%d)\n",(double)msg.get_temp_sht21()/100,msg.get_temp_sht21());
      System.out.format("Pressure (ms5607):\t\t%8.3f mbar \t(%d)\n",(double)msg.get_press()/100,msg.get_press());
      System.out.format("Light (bh1750fvi):\t\t%8d lx\n",msg.get_light());
      System.out.format("Accelerometer (bma180):\t\t%8.3f %8.3f %8.3f \t\n", (double)msg.get_accelx(), (double)msg.get_accely(), (double)msg.get_accelz());
      System.out.format("Voltage:\t\t\t%8.3f V \t(%d)\n",(double)msg.get_voltage()/1000,msg.get_voltage());
      System.out.println("Switch:\t\t\t\t"+(msg.get_batswitch()==0?"Rechargable":"Not Rechargable"));
      System.out.println("Button:\t\t\t\t"+(msg.get_button()==0?"Released":"Pressed"));
      System.out.println();
    }
  }
  
  private static void usage() {
    System.err.println("usage: UcminiSensor [-comm <source>]. Default source: serial@/dev/ttyUSB0:ucmini");
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
        usage();
        System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    if (source == null) {
      source = "serial@/dev/ttyUSB0:ucmini";
    }
    phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);

    MoteIF mif = new MoteIF(phoenix);
    UcminiSensor serial = new UcminiSensor(mif);
  }
}

