/**
 * This file contains the default baud rate for current TinyOS
 * platforms. Don't add anything but platform entries, as this file is also
 * #included in C code to get the table, with appropriate #define's to
 * avoid problems...
*/
package net.tinyos.packet;

class BaudRate {
    static void init() throws Exception {
	/* The Platform.x argument is there for when this code is #include'd
	   into C */
	Platform.add(Platform.x, "mica",       19200);
	Platform.add(Platform.x, "mica2",      57600);
	Platform.add(Platform.x, "mica2dot",   19200);
	Platform.add(Platform.x, "telos",      115200);
	Platform.add(Platform.x, "telosb",     115200);
	Platform.add(Platform.x, "tinynode",     115200);
	Platform.add(Platform.x, "tmote",      115200);
	Platform.add(Platform.x, "micaz",      57600);
	Platform.add(Platform.x, "eyesIFX",       57600);
	Platform.add(Platform.x, "intelmote2", 115200);
	Platform.add(Platform.x, "iris",      57600);
    }
}
