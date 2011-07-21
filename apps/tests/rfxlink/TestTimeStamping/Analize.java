/** Copyright (c) 2011, University of Szeged
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
* Author: Miklos Maroti
*/

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.util.*;

public class Analize implements MessageListener
{
	static final int NUMBER_OF_MOTES = TestMsg.numElements_history_times(0);
	static final int HISTORY_SIZE = TestMsg.numElements_history_times(1);  
	
	int maxSamples = 100;
	int samples = 0;
	
	public static void main(String[] args)
	{
		Analize analize = new Analize();
		String comm = null;

		for(int i = 0; i < args.length; ++i)
		{
			if( args[i].equals("-comm") && i < args.length-1 )
				comm = args[++i];
			else if( args[i].equals("-samples") && i < args.length-1 )
				analize.maxSamples = Integer.parseInt(args[++i]);
			else
			{
				System.err.println("usage: Analize [-comm <source>] [-samples <samples>]");
				System.exit(1);
			}
		}

		PhoenixSource phoenix;
		if( comm == null )
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		else
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);

	    MoteIF mote = new MoteIF(phoenix);
	    System.out.println("Collecting " + analize.maxSamples 
	    		+ " synchronization points from " + NUMBER_OF_MOTES + " motes...");
	    mote.registerListener(new TestMsg(), analize);
	}

	int[] seqnos = new int[NUMBER_OF_MOTES];

	int resolveSeqno(int sender, int seqno)
	{
		seqno &= 0xFF;
		
    	while( (seqnos[sender] & 0xFF) != seqno )
    		seqnos[sender] += 1;
    	
    	return seqnos[sender];
	}

	static class Entry
	{
		int sender;
		int seqno;
		long[] times = new long[NUMBER_OF_MOTES];
		boolean reported = false;
		
		boolean isFull()
		{
			for(int i = 0; i < times.length; ++i)
				if( times[i] == 0 )
					return false;
			
			return true;
		}
		
		public String toString()
		{
			String s = "sender " + sender + " :";

			for(int i = 0; i < times.length; ++i)
				s += " " + times[i];

			return s;
		}
	}

	ArrayList<Entry> entries = new ArrayList<Entry>();
	
	Entry getEntry(int sender, int seqno)
	{
		for(Entry entry : entries)
		{
			if( entry.sender == sender && entry.seqno == seqno )
				return entry;
		}
		
		Entry entry = new Entry();
		entry.sender = sender;
		entry.seqno = seqno;
		
		entries.add(entry);
		return entry;
	}
	
    public synchronized void messageReceived(int dest_addr, Message amsg)
    {
    	if( !(amsg instanceof TestMsg) )
    	{
    		System.err.println("Incorrect message format");
    		return;
    	}
    		
    	TestMsg msg = (TestMsg)amsg;

    	int reporter = msg.getSerialPacket().get_header_src();
    	if( reporter < 0 || reporter >= NUMBER_OF_MOTES )
    	{
    		System.err.println("Incorrect nodeid in message");
    		return;
    	}

    	for(int sender = 0; sender < NUMBER_OF_MOTES; ++sender)
    	{
    		int seqNo = resolveSeqno(sender, msg.getElement_history_seqno(sender));

    		for(int history = HISTORY_SIZE - 1; history >= 0; --history)
    		{
    			if( seqNo - history < 0 )
    				continue;

    			Entry entry = getEntry(sender, seqNo - history);
    			long time = msg.getElement_history_times(sender, history);
    			
    			if( entry.times[reporter] != 0 && entry.times[reporter] != time )
    				System.err.println("Conflicting times received");

    			entry.times[reporter] = time;

    			if( entry.isFull() && ! entry.reported )
    			{
    				samples += 1;
    				entry.reported = true;
       				System.out.println(entry);
       				
       				if( samples >= maxSamples )
       					analize();
    			}
    			else if( samples == 0 && entries.size() >= 20 )
    			{
       				System.err.println("Messages are not received form all motes");
       				System.exit(1);
    			}
    		}
    	}
    }

    void analize()
    {
    	System.out.println("Analizing data...");

        LinearEquations equations = new LinearEquations();
    	
    	for(Entry entry : entries)
    	{
    		if( ! entry.isFull() )
    			continue;

    		for(int receiver = 0; receiver < NUMBER_OF_MOTES; ++receiver)
    		{
    			if( receiver == entry.sender )
    				continue;

    			LinearEquations.Equation equation = equations.createEquation();

    			if( entry.sender != 0 )
    			{
    				equation.addCoefficient("offset" + entry.sender, 1.0);
    				equation.addCoefficient("skew" + entry.sender, entry.times[entry.sender]);
    			}
    			else
    				equation.addConstant(-entry.times[0]);

    			if( receiver != 0 )
    			{
    				equation.addCoefficient("offset" + receiver, -1.0);
    				equation.addCoefficient("skew" + receiver, -entry.times[receiver]);
    			}
    			else
    				equation.addConstant(entry.times[0]);
    			
    			equation.addCoefficient("delay", 1.0);
    			
    			equations.addEquation(equation);
    		}
    	}
    	
    	LinearEquations.Solution solution = equations.solveLeastSquares();
    	
    	for(int i = 0; i < NUMBER_OF_MOTES; ++i)
    	{
    		System.out.println("offset " + i + " = " + (i == 0 ? 0.0 : solution.getValue("offset" + i))
    				+ "\tskew " + i + " = " + (i == 0 ? 1.0 : solution.getValue("skew" + i)));
    	}
		
		System.out.println("transmit delay = " + solution.getValue("delay"));
		System.out.println("maximum error = " + solution.getMaximumError());
		System.out.println("average error = " + solution.getAverageError());
    	
    	System.exit(0);
    }
}
