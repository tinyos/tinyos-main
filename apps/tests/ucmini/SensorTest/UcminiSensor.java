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
    this.moteIF.registerListener(new UcminiSensorCalib(), this);
    this.moteIF.registerListener(new UcminiSensorMeas(), this);
    UcminiSensorCalib payload=new UcminiSensorCalib();
    try{
      this.moteIF.send(0xffff, payload);
    }
    catch (IOException exception) {
      System.err.println("Exception thrown when sending packets. Exiting.");
      System.err.println(exception);
      System.exit(1);
    }
  }

  public void messageReceived(int to, Message message) {
    if(message instanceof UcminiSensorCalib){
    	UcminiSensorCalib msg = (UcminiSensorCalib)message;
    	calibration[0]=msg.getElement_coefficient(0);
    	calibration[1]=msg.getElement_coefficient(1);
    	calibration[2]=msg.getElement_coefficient(2);
    	calibration[3]=msg.getElement_coefficient(3);
    	calibration[4]=msg.getElement_coefficient(4);
    	calibration[5]=msg.getElement_coefficient(5);
    	System.out.println("Ms5607 calibration:");
    	System.out.println("c1="+calibration[0]+"; c2="+calibration[1]+"; c3="+calibration[2]+"; c4="+calibration[3]+
    					   "; c5="+calibration[4]+"; c6="+calibration[5]);
    } else if(message instanceof UcminiSensorMeas){
      UcminiSensorMeas msg = (UcminiSensorMeas)message;
      double rh=-6+125*((double)msg.get_humi()/65536);
      System.out.format("Humidity (sht21):\t\t%8.3f %% \t(%d)\n",rh, msg.get_humi());
      double temp=-46.85+175.72*((double)msg.get_temp()/65536);
      System.out.format("Temperature (sht21):\t\t%8.3f \u00B0C \t(%d)\n",temp,msg.get_temp());
      double temp3=1.13*msg.get_temp3()-272.8;
      System.out.format("Temperature (atmega128rfa1):\t%8.3f \u00B0C \t(%d)\n", temp3, msg.get_temp3());
      System.out.format("Temperature (ms5607):\t\t%8.3f \u00B0C \t(%d)\n",(double)msg.get_temp2()/100,msg.get_temp2());
      System.out.format("Pressure (ms5607):\t\t%8.3f mbar \t(%d)\n",(double)msg.get_press()/100,msg.get_press());
      System.out.format("Light (bh1750fvi):\t\t%8d lx\n",msg.get_light());
//      System.out.println("Voltage (atmega128rfa1):\t"+msg.get_voltage());
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

