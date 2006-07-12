package net.tinyos.packet;

import java.util.*;

class Platform {
    static int x;
    static Hashtable platforms;

    static void add(int dummy, String name, int baudrate) {
	platforms.put(name, new Integer(baudrate));
    }

    static int get(String name) {
	if (platforms == null) {
	    platforms = new Hashtable();
            try {
	      BaudRate.init();
            }
            catch (Exception e) {
              System.err.println("Failed to initialize baud rates for platforms. Serial communication may not work properly.");
            }
	}
	Object val = platforms.get(name);

	if (val != null)
	    return ((Integer)val).intValue();
	else
	    return -1;
    }
}
