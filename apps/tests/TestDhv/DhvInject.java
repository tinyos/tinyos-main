
import java.io.*;
import net.tinyos.message.*;
import net.tinyos.util.*;

public class DhvInject implements MessageListener
{
    MoteIF mote;

    DhvInject(DhvMsg dhvmsg) {
        mote = new MoteIF(PrintStreamMessenger.err);
        mote.registerListener(dhvmsg, this);
    }

    public synchronized void messageReceived(int dest_addr, Message message)
    {
	// do nothing for now
    }

    void sendDhvDataMsg(int key, long version, short[] data) {
	int totalsize = DhvMsg.DEFAULT_MESSAGE_SIZE +
	    DhvDataMsg.DEFAULT_MESSAGE_SIZE +
	    DhvData.DEFAULT_MESSAGE_SIZE;
	DhvMsg dm = new DhvMsg(totalsize);
	dm.set_type((short)3);

	DhvDataMsg ddm = new DhvDataMsg(dm, DhvMsg.DEFAULT_MESSAGE_SIZE);
	ddm.set_key(key);
        ddm.set_version(version << 16);
        ddm.set_size((short)data.length);

        DhvData dd = new DhvData(ddm, DhvDataMsg.DEFAULT_MESSAGE_SIZE); 
        dd.set_data(data);

        try {
	    mote.send(MoteIF.TOS_BCAST_ADDR, dd);
	}
        catch(IOException e) {
	    System.err.println("Cannot send message");
	}
    }

    public static void main(String args[]) {
	int i;

        System.out.println("Usage: java DhvInject [key] [version] [hex data delimit space in quotes]");
        int k = Integer.parseInt(args[0], 16);
        long v = Long.parseLong(args[1]);
        String hexdata[] = args[2].split(" ");
	short d[];

        if(hexdata.length > 16) {
            System.err.println("Data too long, keep it <= 16 bytes please");
	}

	d = new short[hexdata.length];
        for(i = 0; i < d.length; i++)
            d[i] = Short.parseShort(hexdata[i], 16);

        System.out.println("Key: " + k);
        System.out.println("Version: " + v);
        System.out.print("Data: ");
        for(i = 0; i < d.length; i++) {
            System.out.print(d[i] + " ");
	}
        System.out.println();

        DhvInject dhvinject = new DhvInject(new DhvMsg());
        dhvinject.sendDhvDataMsg(k, v, d);
    }
}
