// $Id: tos-serial-debug.c,v 1.5 2010-06-29 22:07:42 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifdef __CYGWIN__
#include <windows.h>
#endif

#define BAUDRATE B19200 //the baudrate that the device is talking
#define SERIAL_DEVICE "/dev/ttyS0" //the port to use.

int input_stream;

void print_usage(char *name);
void open_input(int argc, char **argv);

int main(int argc, char ** argv) {
    int n = 0;

    if (argc > 3 || argc > 1 && argv[1][0] == '-') {
	print_usage(argv[0]);
	exit(2);
    }
    open_input(argc, argv);
    while(1) { 
	unsigned char c;
	int cnt = read(input_stream, &c, 1);

	if (cnt < 0) {
	    perror("error reading from serial port");
	    exit(2);
	}
	if (cnt == 1) {
	    if (c == 0x7e || ++n == 26) {
		n = 0;
		printf("\n");
	    }
	    printf("%02x ", c);
	    fflush(stdout);
	}
    }
}

void print_usage(char *name){
    //usage...
    fprintf(stderr, "usage: %s [serial port] [baudrate]\n", name);
    fprintf(stderr, "Default serial port is " SERIAL_DEVICE ", default baud rate is 19200\n");
}


void open_input(int argc, char **argv) {
    /* open input_stream for read/write */ 
    struct termios newtio;
    const char *name = SERIAL_DEVICE;
    unsigned long baudrate = BAUDRATE;

    if (argc > 1)
	name = argv[1];
    if (argc > 2) {
	int reqrate = atoi(argv[2]);

	switch (reqrate) {
#ifdef B50
	case 50: baudrate = B50; break;
#endif
#ifdef B75
	case 75: baudrate = B75; break;
#endif
#ifdef B110
	case 110: baudrate = B110; break;
#endif
#ifdef B134
	case 134: baudrate = B134; break;
#endif
#ifdef B150
	case 150: baudrate = B150; break;
#endif
#ifdef B200
	case 200: baudrate = B200; break;
#endif
#ifdef B300
	case 300: baudrate = B300; break;
#endif
#ifdef B600
	case 600: baudrate = B600; break;
#endif
#ifdef B1200
	case 1200: baudrate = B1200; break;
#endif
#ifdef B1800
	case 1800: baudrate = B1800; break;
#endif
#ifdef B2400
	case 2400: baudrate = B2400; break;
#endif
#ifdef B4800
	case 4800: baudrate = B4800; break;
#endif
#ifdef B9600
	case 9600: baudrate = B9600; break;
#endif
#ifdef B19200
	case 19200: baudrate = B19200; break;
#endif
#ifdef B38400
	case 38400: baudrate = B38400; break;
#endif
#ifdef B57600
	case 57600: baudrate = B57600; break;
#endif
#ifdef B115200
	case 115200: baudrate = B115200; break;
#endif
#ifdef B230400
	case 230400: baudrate = B230400; break;
#endif
#ifdef B460800
	case 460800: baudrate = B460800; break;
#endif
#ifdef B500000
	case 500000: baudrate = B500000; break;
#endif
#ifdef B576000
	case 576000: baudrate = B576000; break;
#endif
#ifdef B921600
	case 921600: baudrate = B921600; break;
#endif
#ifdef B1000000
	case 1000000: baudrate = B1000000; break;
#endif
#ifdef B1152000
	case 1152000: baudrate = B1152000; break;
#endif
#ifdef B1500000
	case 1500000: baudrate = B1500000; break;
#endif
#ifdef B2000000
	case 2000000: baudrate = B2000000; break;
#endif
#ifdef B2500000
	case 2500000: baudrate = B2500000; break;
#endif
#ifdef B3000000
	case 3000000: baudrate = B3000000; break;
#endif
#ifdef B3500000
	case 3500000: baudrate = B3500000; break;
#endif
#ifdef B4000000
	case 4000000: baudrate = B4000000; break;
#endif
	default:
	    fprintf(stderr, "Unknown baudrate %s, defaulting to 19200\n",
		    argv[2]);
	}
    }
    
    input_stream = open(name, O_RDWR|O_NOCTTY);
    if (input_stream == -1) {
	fprintf(stderr, "Failed to open %s", name);
	perror("");
	fprintf(stderr, "Make sure the user has permission to open device.\n");
	exit(2);
    }
    printf("%s input_stream opened\n", name);
#ifdef __CYGWIN__
    /* For some very mysterious reason, this incantation is necessary to make
       the serial port work under some windows machines */
    HANDLE handle = (HANDLE)get_osfhandle(input_stream);
    DCB dcb;
    if (!(GetCommState(handle, &dcb) &&
	  SetCommState(handle, &dcb))) {
      fprintf(stderr, "serial port initialisation problem\n");
      exit(2);
    }
#endif

    /* Serial port setting */
    memset(&newtio, 0, sizeof(newtio));
    newtio.c_cflag = CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNPAR | IGNBRK;
    cfsetispeed(&newtio, baudrate);
    cfsetospeed(&newtio, baudrate);

    tcflush(input_stream, TCIFLUSH);
    tcsetattr(input_stream, TCSANOW, &newtio);
}
