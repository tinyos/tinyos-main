/*
 * Copyright (c) 2003-2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 * 
 * Author: Miklos Maroti
 */

package net.tinyos.util;

import net.tinyos.packet.*;
import net.tinyos.util.PrintStreamMessenger;

public class DiagMsg implements PacketListenerIF {
    
    protected String delimiter = " ";
    protected java.text.SimpleDateFormat timestamp = new java.text.SimpleDateFormat("HH:mm:ss");
    
    static final int PACKET_TYPE_FIELD = 7;
    static final int PACKET_LENGTH_FIELD = 5;
    static final int PACKET_DATA_FIELD = 8;
    static final int PACKET_CRC_SIZE = 0;
    static final byte AM_DIAG_MSG = (byte)0xB1;
    
    protected PhoenixSource forwarder;
    
    public DiagMsg(PhoenixSource forwarder)
    {
    	this.forwarder = forwarder;
		forwarder.registerPacketListener(this);
    }

	public void run()
	{
		forwarder.run();
	}

	public static void main(String[] args) throws Exception 
	{
		PhoenixSource phoenix = null;

		if( args.length == 0 )
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		else if( args.length == 2 && args[0].equals("-comm") )
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		else
		{
			System.err.println("usage: DiagMsg [-comm <source>]");
			System.exit(1);
		}

		DiagMsg listener = new DiagMsg(phoenix);
		listener.run();
	}

	public void packetReceived(byte[] packet) 
    {
        if( packet[PACKET_TYPE_FIELD] == AM_DIAG_MSG ) {
            try 
            {
            	System.out.println(timestamp.format(new java.util.Date()) + " " + decode(packet));
            }
            catch(Exception e) 
            {
                System.out.println(e.getMessage());
            }
        }
    }
    
    protected byte[] packet;
    protected int end;
    protected int head;
    protected StringBuffer line;
    
    protected synchronized String decode(byte[] packet) throws Exception 
    {
        this.packet = packet;
        
        head = PACKET_DATA_FIELD;
        end = PACKET_DATA_FIELD + packet[PACKET_LENGTH_FIELD];
        if( end < head || end > packet.length - PACKET_CRC_SIZE )
            throw new Exception("illegal message length");

        line = new StringBuffer();

        while(head < end) {
            byte code = getByte();

            addSimple(code & 0xF);
            addSimple((code >> 4) & 0xF);
        }

        // delete the leading space
        if( line.length() > 0 && line.substring(0, delimiter.length()).equals(delimiter) )
            line.delete(0, delimiter.length());

        return new String(line);
    }

    static final int TYPE_END = 0;
    static final int TYPE_INT8 = 1;
    static final int TYPE_UINT8 = 2;
    static final int TYPE_HEX8 = 3;
    static final int TYPE_INT16 = 4;
    static final int TYPE_UINT16 = 5;
    static final int TYPE_HEX16 = 6;
    static final int TYPE_INT32 = 7;
    static final int TYPE_UINT32 = 8;
    static final int TYPE_HEX32 = 9;
    static final int TYPE_FLOAT = 10;
    static final int TYPE_CHAR = 11;
    static final int TYPE_INT64 = 12;
    static final int TYPE_UINT64 = 13;
    static final int TYPE_ARRAY = 15;

    protected void addSimple(int type) throws Exception
    {
        switch(type) {
            case TYPE_END:                 break;
            case TYPE_INT8:   addInt8();   break;
            case TYPE_UINT8:  addUint8();  break;
            case TYPE_HEX8:   addHex8();   break;
            case TYPE_INT16:  addInt16();  break;
            case TYPE_UINT16: addUint16(); break;
            case TYPE_HEX16:  addHex16();  break;
            case TYPE_INT32:  addInt32();  break;
            case TYPE_UINT32: addUint32(); break;
            case TYPE_HEX32:  addHex32();  break;
            case TYPE_FLOAT:  addReal();   break;
            case TYPE_CHAR:   addChar();   break;
            case TYPE_INT64:  addInt64();  break;
            case TYPE_UINT64: addUint64(); break;
            case TYPE_ARRAY:  addArray();  break;
            
            default:
                line.append(delimiter + "unknown");
        }
    }
    
    protected void addArray() throws Exception 
    {
        int len = getByte();
        int type = (len >> 4) & 0xF;
        len &= 0xF;
        
        if( type == TYPE_CHAR )
            addStr(len);
        else {
            line.append(delimiter + "[");
            
            while( --len >= 0 )
                addSimple(type);
            
            line.append(" ]");
        }
    }
    
    protected void check(int len) throws Exception
    {
        if( head + len > end )
            throw new Exception("illegal message format");
    }
    
    protected byte getByte() throws Exception 
    {
        check(1);
        byte ret = packet[head];
        head += 1;
        return ret;
    }
    
    protected short getShort() throws Exception 
    {
        short a,b;
        check(2);
        
        a = packet[head];            a &= 0x00FF;
        b = packet[head+1]; b <<= 8; b &= 0xFF00; a |= b;
        
        head += 2;
        return a;
    }
    
    protected int getInt() throws Exception 
    {
        int a,b;
        check(4);
        
        a = packet[head];             a &= 0x000000FF;
        b = packet[head+1]; b <<= 8;  b &= 0x0000FF00; a |= b;
        b = packet[head+2]; b <<= 16; b &= 0x00FF0000; a |= b;
        b = packet[head+3]; b <<= 24; b &= 0xFF000000; a |= b;
        
        head += 4;
        return a;
    }
    
    protected long getLong() throws Exception 
    {
        long a,b;
        check(8);
        
        a = packet[head];             a &= 0x00000000000000FF;
        b = packet[head+1]; b <<= 8;  b &= 0x000000000000FF00; a |= b;
        b = packet[head+2]; b <<= 16; b &= 0x0000000000FF0000; a |= b;
        b = packet[head+3]; b <<= 24; b &= 0x00000000FF000000; a |= b;
        b = packet[head+4]; b &= 0x00000000000000FF; b <<= 32; a |= b;
        b = packet[head+5]; b &= 0x00000000000000FF; b <<= 40; a |= b;
        b = packet[head+6]; b &= 0x00000000000000FF; b <<= 48; a |= b;
        b = packet[head+7]; b &= 0x00000000000000FF; b <<= 56; a |= b;
        
        head += 8;
        return a;
    }
    
    protected void addUint8() throws Exception 
    {
        String value = Integer.toString(getByte() & 0xFF);
        line.append(delimiter + value);
    }
    
    protected void addInt8() throws Exception 
    {
        String value = Byte.toString(getByte());
        line.append(delimiter + value);
    }
    
    protected void addHex8() throws Exception 
    {
        String value = Integer.toHexString(getByte() & 0xFF);
        
        line.append(delimiter + "0x");
        for(int i = value.length(); i < 2; ++i)
            line.append('0');
        line.append(value);
    }
    
    protected void addUint16() throws Exception 
    {
        String value = Integer.toString(getShort() & 0xFFFF);
        line.append(delimiter + value);
    }
    
    protected void addInt16() throws Exception 
    {
        String value = Short.toString(getShort());
        line.append(delimiter + value);
    }
    
    protected void addHex16() throws Exception 
    {
        String value = Integer.toHexString(getShort() & 0xFFFF);
        
        line.append(delimiter + "0x");
        for(int i = value.length(); i < 4; ++i)
            line.append('0');
        line.append(value);
    }
    
    protected void addUint32() throws Exception 
    {
        String value = Long.toString(getInt() & 0xFFFFFFFF);
        line.append(delimiter + value);
    }
    
    protected void addInt32() throws Exception 
    {
        String value = Integer.toString(getInt());
        line.append(delimiter + value);
    }
    
    protected void addHex32() throws Exception 
    {
        String value = Integer.toHexString(getInt());
        
        line.append(delimiter + "0x");
        for(int i = value.length(); i < 8; ++i)
            line.append('0');
        line.append(value);
    }
    
    protected void addInt64() throws Exception 
    {
        String value = Long.toString(getLong());
        line.append(delimiter + value);
    }
    
    protected void addUint64() throws Exception 
    {
        String value = Long.toString(getLong());
        line.append(delimiter + value);
    }
    
    protected void addReal() throws Exception 
    {
        float value = Float.intBitsToFloat(getInt());
        line.append(delimiter + Float.toString(value));
    }
    
    protected void addChar() throws Exception 
    {
        char value = (char)getByte();
        line.append(delimiter + "'" + value + "'");
    }
    
    protected void addStr(int len) throws Exception 
    {
        line.append(delimiter + "\"");
        
        while( --len >= 0 )
            line.append((char)getByte());
        
        line.append('"');
    }
}
