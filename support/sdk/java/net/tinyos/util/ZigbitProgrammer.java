/** Copyright (c) 2010, University of Szeged
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

package net.tinyos.util;

import net.tinyos.comm.*;
import java.io.*;
import java.util.*;

/**
 * This class implements the ZigBit bootloader protocol and can reset
 * the mote through a serial message. 
 */
public class ZigbitProgrammer implements SerialPortListener
{
	TOSSerial serial;
	protected InputStream is;
	protected OutputStream os;
	
	public byte[] readBytes(int count, long timeout) throws IOException
	{
		long deadline = System.currentTimeMillis() + timeout;
		byte[] bytes = new byte[count];

		for(int i = 0; i < count; )
		{
			synchronized(is)
			{
				if( is.available() > 0 )
					bytes[i++] = (byte)is.read();
				else
				{
					timeout = deadline - System.currentTimeMillis();
					if( timeout <= 0 )
						return null;
						
					try
					{
						is.wait(timeout);
					}
					catch(InterruptedException e)
					{
						return null;
					}
				}
			}
		}

		return bytes;
	}
	
	public void serialEvent(SerialPortEvent ev)
	{
		synchronized(is)
		{
			is.notify();
		}
	}

	public void writeBytes(byte[] bytes) throws IOException
	{
		os.write(bytes);
		os.flush();
	}

	public void closePort() throws IOException
	{
		if( serial != null )
		{
			is.close();
			os.close();
			serial.close();
			
			serial = null;
			is = null;
			os = null;
		}
	}
	
	public void openPort(String port) throws IOException
	{
		closePort();
		
		try
		{
			serial = new TOSSerial(port);
		}
		catch(Exception e)
		{
			System.out.println("Cound not open port: " + port);
			System.exit(5);
		}
		
		serial.addListener(this);
		serial.notifyOn(SerialPortEvent.DATA_AVAILABLE, true);

		is = serial.getInputStream();
		os = serial.getOutputStream();
	}

	public void setBaudrate(int baudrate)
	{
		serial.setSerialPortParams(baudrate, 8, SerialPort.STOPBITS_1, false);
	}
	
	public boolean resetTinyOS(int baudrate) throws IOException
	{
		byte[] req = new byte[] { (byte)0x7e, (byte)0x44, (byte)0x19, (byte)0x72, 'R', 'S', 'T', (byte)0xb9, (byte)0x1e, (byte)0x7e };
		byte[] ack = new byte[] { (byte)0x7e, (byte)0x45, (byte)0x72, 'Z', 'B', 'P', (byte)0x76, (byte)0x35, (byte)0x7e };
		byte[] response = new byte[ack.length];
		
		int[] baudrates;
		if( baudrate == 0 )
			baudrates = new int[] { 57600, 230400, 115200, 38400 };
		else
			baudrates = new int[] { baudrate };
		
		System.out.print("Resetting TinyOS ..");
		for(int i = 0; i < 3; ++i)
		{
			for(int j = 0; j < baudrates.length; ++j)
			{
				setBaudrate(baudrates[j]);

				for(int k = 0; k < 2; ++k)
				{
					System.out.print('.');
			
					writeBytes(req);
					long deadline = System.currentTimeMillis() + 200;
			
					for(;;)
					{
						long timeout = deadline - System.currentTimeMillis();
						if( timeout <= 0 )
							break;
				
						byte[] b = readBytes(1, timeout);
						if( b != null )
						{
							System.arraycopy(response, 1, response, 0, response.length-1);
							response[response.length-1] = b[0];
					
							if( Arrays.equals(response, ack) )
							{
								System.out.println(" done");
								return true;
							}
						}
					}
				}
			}
		}
		
		System.out.println(" failed");
		return false;
	}

	public void accessBootloder() throws IOException
	{
		byte[] req = new byte[] { (byte)0xB2, (byte)0xA5, (byte)0x65, (byte)0x4B };
		byte[] ack = new byte[] { (byte)0x69, (byte)0xD3, (byte)0xD2, (byte)0x26 };
		
		System.out.print("Connecting to bootloader ..");
		for(int i = 0; i < 20; ++i)
		{
			System.out.print('.');
			
			writeBytes(req);
			byte[] response = readBytes(4, 500);
			if( response != null && Arrays.equals(response, ack) )
			{
				System.out.println(" done");
				return;
			}
		}
		
		System.out.println(" failed");
		System.exit(1);
	}

	public void uploadFile(String filename) throws FileNotFoundException, IOException
	{
		Scanner scanner = new Scanner(new File(filename));
		
		ArrayList<String> lines = new ArrayList<String>();
		while( scanner.hasNextLine() ) 
			lines.add(scanner.nextLine());

		byte[] ack = new byte[] { (byte)0x4D, (byte)0x5A, (byte)0x9A, (byte)0xB4 };
		byte[] nak = new byte[] { (byte)0x2D, (byte)0x59, (byte)0x5A, (byte)0xB2 };
		
		System.out.print("Writing " + lines.size() + " pages to flash ...");
		
		for(int i = 0; i < lines.size(); ++i)
		{
			String line = lines.get(i);
			byte[] bytes = new byte[1 + line.length()/2];
			
			bytes[0] = (byte)line.charAt(0);
			bytes[1] = (byte)line.charAt(1);

			for(int j = 2; j < bytes.length; ++j)
				bytes[j] = (byte)Integer.parseInt(line.substring(-2 + j*2, j*2), 16);
			
			writeBytes(bytes);
			byte[] response = readBytes(4, 50);

			if( response == null )
			{
				System.out.println(" no response");
				System.exit(2);
			}
			else if( Arrays.equals(response, ack) )
			{
				if( i % 16 == 0 )
					System.out.print(".");
			}
			else if( Arrays.equals(response, nak) )
			{
				System.out.println(" not accepted");
				System.exit(3);
			}
			else
			{
				System.out.println(" incorrect response");
				System.exit(4);
			}
		}
		System.out.println(" done");
	}
	
	public static void main(String[] args) throws IOException, InterruptedException
	{
		String port = null;
		int baudrate = 0;
		boolean reset = false;
		boolean askForReset=false;
		String srec = null;
		int sleep = 0;

		if( args.length == 0 )
		{
			System.out.println("Usage: java net.tinyos.util.ZigbitProgrammer <flags>");
			System.out.println("  where flags are the following");
			System.out.println("\t-port <name>\t\tsets the communication port (mandatory)");
			System.out.println("\t-baudrate <rate>\tsets the baudrate of TinyOS serial (0=auto)");
			System.out.println("\t-reset\t\t\tsoftware reset through TinyOS serial");
			System.out.println("\t-askforreset\t\tasks the user to reset the mote if needed");
			System.out.println("\t-sleep <seconds>\twaits (omitted if a reset fails)");
			System.out.println("\t-upload <srec file>\tuploads file through ZigBit bootloader");
			System.exit(0);
		}
		
		for(int i = 0; i < args.length; ++i)
		{
			if( args[i].equals("-port") )
				port = args[++i];
			else if( args[i].equals("-baudrate") )
				baudrate = Integer.parseInt(args[++i]);
			else if( args[i].equals("-reset") )
				reset = true;
			else if( args[i].equals("-askforreset") )
				askForReset = true;
			else if( args[i].equals("-sleep") )
				sleep = Integer.parseInt(args[++i]);
			else if( args[i].equals("-upload") )
				srec = args[++i];
			else
			{
				System.out.println("Incorrect option: " + args[i]);
				System.exit(6);
			}
		}
		
		if( port == null )
		{
			System.out.println("The communication port is not specified");
			System.exit(6);
		}
		
		ZigbitProgrammer programmer = new ZigbitProgrammer();
		
		if( reset )
		{
			programmer.openPort(port);
			if ( programmer.resetTinyOS(baudrate) == false ){
				sleep=0;
			} else
				askForReset=false;
			programmer.closePort();
		}
		if( askForReset )
		{
			System.out.println("Please reset the mote, than press enter");
			System.in.read();
		}
		else if( sleep > 0 )
			Thread.sleep(1000 * sleep);
		if( srec != null )
		{
			programmer.openPort(port);
			programmer.setBaudrate(38400);
			programmer.accessBootloder();
			programmer.uploadFile(srec);
			programmer.closePort();
		}
	}
}
