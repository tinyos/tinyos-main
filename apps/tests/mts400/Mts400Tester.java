/** Copyright (c) 2009, University of Szeged
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
* Author: Zoltan Kincses
*/

import static java.lang.System.out;
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.packet.*;

class Mts400Tester implements MessageListener{
	private PhoenixSource phoenix;
	private MoteIF mif;
		
	public Mts400Tester(final String source){
		phoenix=BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		mif = new MoteIF(phoenix);
		mif.registerListener(new DataMsg(),this);
	}
	
	public void messageReceived(int dest_addr,Message msg){
		if(msg instanceof DataMsg){
			DataMsg results = (DataMsg)msg;
			int[] taosCalcData = null;
			double[] sensirionCalcData=null;
			out.println("The measured results are ");
			out.println();
			out.println("Accelerometer X axis:   "+results.get_AccelX_data());
			out.println("Accelerometer Y axis:   "+results.get_AccelY_data());
			out.println("Intersema temperature:  "+results.getElement_Intersema_data(0));
			out.println("Intersema pressure:     "+results.getElement_Intersema_data(1));
			sensirionCalcData=calculateSensirion(results.get_Temp_data(),results.get_Hum_data());
			out.printf("Sensirion temperature:  %.2f\n",sensirionCalcData[0]);
			out.printf("Sensirion humidity:     %.2f\n",sensirionCalcData[1]);
			taosCalcData=calculateTaos(results.get_VisLight_data(),results.get_InfLight_data());
			out.println("Taos visible light:     "+taosCalcData[0]);
			out.println("Taos infrared light:    "+taosCalcData[1]);
		}
			
	}
	
	private int[] calculateTaos(int VisibleLight,int InfraredLight){
		final int CHORD_VAL[]={0,16,49,115,247,511,1039,2095};
		final int STEP_VAL[]={1,2,4,8,16,32,64,128};
		int chordVal,stepVal;
		int[] lightVal=new int[2];
		
		chordVal=(VisibleLight>>4) & 7;
		stepVal=VisibleLight & 15;
		lightVal[0]=CHORD_VAL [chordVal]+stepVal*STEP_VAL[chordVal];
		chordVal=(InfraredLight>>4)&7;
		stepVal=VisibleLight & 15;
		lightVal[1]=CHORD_VAL[chordVal]+stepVal*STEP_VAL[chordVal];
		return lightVal;
	}
	
	private double[] calculateSensirion(int Temperature,int Humidity){
		double [] converted = new double[2]; 
		
		converted[0]=-39.4+(0.01*(double)Temperature);
		converted[1]=(-2.0468+0.0367*(double)Humidity-0.0000015955*Math.pow((double)Humidity,(double )2))+(converted[0]-25)*(0.01+0.00008*(double)Humidity);
			
		return converted;
	}
	
	public static void main (String[] args) {
		if ( args.length == 2 && args[0].equals("-comm") ) {
			Mts400Tester hy = new Mts400Tester(args[1]);
		} else {
			System.err.println("usage: java Mts400Tester [-comm <source>]");
			System.exit(1);
		}
		
	}

}