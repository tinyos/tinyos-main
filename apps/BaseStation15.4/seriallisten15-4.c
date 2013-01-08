#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

#include <sys/timeb.h>

#include "serialsource.h"

FILE * f;						// file handle for capture file
unsigned int snap = 65535;

typedef struct pcaprec_hdr_s {	// header for each packet
  unsigned int ts_sec;
  unsigned int ts_usec;
  unsigned int incl_len;
  unsigned int orig_len;
} pcaprec_hdr_t;

typedef struct pcap_hdr_s {		// header for capture file
  unsigned int magic_number;
  unsigned short version_major;
  unsigned short version_minor;
  int thiszone;
  unsigned int sigfigs;
  unsigned int snaplen;
  unsigned int network;
} pcap_hdr_t;


static char *msgs[] = {
  "unknown_packet_type",
  "ack_timeout"	,
  "sync"	,
  "too_long"	,
  "too_short"	,
  "bad_sync"	,
  "bad_crc"	,
  "closed"	,
  "no_memory"	,
  "unix_error"
};

void capture_global(){		// write file header with values for 802.15.4 - no change needed
  pcap_hdr_t globalheader;

  globalheader.magic_number = 0xa1b2c3d4;
  globalheader.version_major = 0x0204;
  globalheader.version_minor = 0x0204;
  globalheader.thiszone = -3600;
  globalheader.sigfigs = 0;
  globalheader.snaplen = snap;
  globalheader.network = 195;

  fwrite(&globalheader, sizeof(globalheader),1,f);

}

void capture_packet_header (int wire_len, int org_len){ // write packet header 
  pcaprec_hdr_t headerpkt;

  struct timeb temps;
  ftime(&temps);

  headerpkt.ts_sec = temps.time;
  headerpkt.ts_usec = temps.millitm;
  headerpkt.incl_len = wire_len;
  headerpkt.orig_len = org_len;

  fwrite(&headerpkt, sizeof(headerpkt), 1, f);
	 
}

void stderr_msg(serial_source_msg problem)
{
  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

void sign_handler(int signum){
  switch (signum) {
    case SIGINT:
     fclose(f);
     exit(0);
     break;
  }
}

enum {
  TOS_SERIAL_802_15_4_ID = 2,
};

int main(int argc, char **argv)
{
  serial_source src;
  int iframes = 0;
  if (argc != 5) {
    fprintf(stderr, "Usage: %s <iframe|tframe> <device> <rate> <capture-file> - dump packets from a serial port\n", argv[0]);
    exit(2);
  }

  if (strncmp(argv[1], "tframe", strlen("tframe")) == 0) {
    iframes = 0;
  }
  else if (strncmp(argv[1], "iframe", strlen("iframe")) == 0) {
    iframes = 1;
  }
  else {
    fprintf(stderr, "Usage: %s <iframe|tframe> <device> <rate> - dump packets from a serial port\n", argv[0]);
    exit(3);
  }

  src = open_serial_source(argv[2], platform_baud_rate(argv[3]), 0, stderr_msg);

  if (!src) {
    fprintf(stderr, "Couldn't open serial port at %s:%s\n",
	    argv[2], argv[3]);
    exit(1);
  }

  f=fopen(argv[4],"wb");				// open capture file, name provided by user
  capture_global();						// write header
  signal(SIGINT, sign_handler);
	      
  for (;;)
    {
      int len, i, plen, x;
      short fcf;
      int offset_serial = 2;
      int offset_meta = 9;
      int offset = offset_serial - offset_meta;
      const unsigned char *packet = read_serial_packet(src, &len);
      unsigned char wireshark_packet[len - offset];
      int intraPan = 0;
      int ack = 0;
      
      if (!packet)
	exit(0);
      else if (packet[0] != TOS_SERIAL_802_15_4_ID) {
	printf("bad packet (serial type is %02x, not %02x)\n", packet[0], TOS_SERIAL_802_15_4_ID);
      }

      plen = packet[1];
      printf("Received packet of length %i: \n", plen);

      if (plen != len) {
	printf("Packet format error: read packet length (%hhx) is different than expected from frame (%hhx).\n", plen, len);
      }
      
      for(x=2; x<len-offset_meta; x++){				// copy raw packet to buffer without seriall overhead
        wireshark_packet[x-2] = packet[x];
      }
      if(plen <= snap){								// write raw packet to file
        capture_packet_header(plen, plen+2);	// 2 byte crc missing
        fwrite(wireshark_packet, 1, plen, f);     
      }

      i = 2;
      // Read in FCF and i+=2
      fcf = packet[i+1] << 8 | packet[i];
      i += 2;
      

      {
	if ((fcf & 0x7) == 0x01) {
	  printf("  Frame type: data\n");
	}
	else if ((fcf & 0x7) == 0x02) {
	  printf("  Frame type: acknowledgement\n");
	  ack = 1;
	}
	else {
	  printf("  Frame type: other 0x%02hhx \n", (fcf & 0x7));
	}

	printf("  Security: %s\n", (fcf & (1 << 3)) ? "enabled":"disabled");
	printf("  Frame pending: %s\n", (fcf & (1 << 4)) ? "yes":"no");
	printf("  Ack request: %s\n", (fcf & (1 << 5)) ? "yes":"no");
	printf("  Intra-PAN: %s\n", (fcf & (1 << 6)) ? "yes":"no");
	intraPan = (fcf & (1 << 6));
      }


      {
	char seqno = packet[i++];
	printf("  Sequence number: 0x%hhx\n", seqno);
      }
      
      if (ack != 1) {	// no addresses, no payload
        {
	  char addrLen = (fcf >> 10) & 0x3;
	  short saddr = 0;
	  long long laddr = 0;

	  // 16- and 64-bit destinations have a PAN ID
	  if (addrLen == 2 || addrLen == 3) { 
	    short destPan = packet[i++] << 8 | packet[i++];
	    printf("  Destination PAN: 0x%02hx\n", destPan);
	  }

	  switch (addrLen) {
	    case 0:
	      printf("  Destination address: none\n");
	      break;
 	    case 1:
	      printf("  Destination address: invalid? (0x01)\n");
	      break;
	    case 2:
	      saddr =  (packet[i] << 8 | packet[i+1]);
	      i += 2;
	      printf("  Destination address: 0x%04hx\n", saddr);
	      break;
	    case 3: {
	      int j;
	      for (j = 0; j < 8; j++) {
	        laddr = laddr << 8;
	        laddr |= packet[i++];
	      }
	      printf("  Destination address: 0x%016llx\n", laddr);
	      break;
	    }
	    default:
	      printf("  Destination address: parse serror\n");
	  }
        }

      
        {
	  char addrLen = (fcf >> 14) & 0x3;
	  short saddr = 0;
	  long long laddr = 0;
 
	  if (!intraPan) { // Intra-PAN packet
	    short srcPan = packet[i] << 8 | packet[i+1];
	    i += 2;
	    printf("  Source PAN: 0x%02hx\n", srcPan);
	  }

	  switch (addrLen) {
	    case 0:
	      printf("  Source address: none\n");
	      break;
	    case 1:
	      printf("  Source address: invalid? (0x01)\n");
	      break;
	    case 2:
	      saddr =  (packet[i] << 8 | packet[i + 1]);
	      i += 2;
	      printf("  Source address: 0x%04hx\n", saddr);
	      break;
	    case 3: {
	      int j;
	      for (j = 0; j < 8; j++) {
	        laddr = laddr << 8;
	        laddr |= packet[i++];
	      }
	      printf("  Source address: 0x%016llx\n", laddr);
	      break;
	    }
	    default:
	      printf("  Source address: parse serror\n");
	  }
        }

        if (iframes) {
	  printf("  I-Frame: %s\n", (packet[i++] == 0x3f)? "yes":"no");
        }
      
        printf("  AM type: 0x%02hhx\n", packet[i++]);

        if (i >= plen) {
	  printf("Packet format error: read packet is shorter than expected.\n");
        }
        else {
	  printf("  Payload: ");
	  for (; i < plen + 2; i++) {		// first two bytes of len where skipped by i but are not counted for plen
	    printf("0x%02hhx ", packet[i]);
	  }

	  printf("\n\n");
        }
      }

      // additional info from tkn15.4 Mac Layer

      printf("  LQI: 0x%02hhx \n", packet[i++]);
      printf("  RSSI: 0x%02hhx \n", packet[i++]);
      printf("  CRC ok: 0x%02hhx \n", packet[i++]);
      printf("  MAC Header length: 0x%02hhx \n", packet[i++]);
      printf("  PHY channel: 0x%02hhx \n", packet[i++]);
      printf("\n");
      printf("  Timestamp: ");

      while(i < len){
	printf("0x%02hhx ", packet[i++]);
      }

      printf("\n\n");
      putchar('\n');

      free((void *)packet);
    }
}
