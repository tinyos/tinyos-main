#include <stdio.h>
#include <stdlib.h>

#include "serialsource.h"

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

void stderr_msg(serial_source_msg problem)
{
  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

enum {
  TOS_SERIAL_802_15_4_ID = 2,
};

int main(int argc, char **argv)
{
  serial_source src;

  if (argc != 3)
    {
      fprintf(stderr, "Usage: %s <device> <rate> - dump packets from a serial port\n", argv[0]);
      exit(2);
    }
  src = open_serial_source(argv[1], platform_baud_rate(argv[2]), 0, stderr_msg);
  if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }
  for (;;)
    {
      int len, i, plen;
      short fcf;
      const unsigned char *packet = read_serial_packet(src, &len);
      int intraPan = 0;
      
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
	}
	else {
	  printf("  Frame type: other\n");
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
      
      printf("  AM type: 0x%02hhx\n", packet[i++]);

      if (i >= plen) {
	printf("Packet format error: read packet is shorter than expected.\n");
      }
      else {
	printf("  Payload: ");
	for (; i < plen; i++) {
	  printf("0x%02hhx ", packet[i]);
	}
	printf("\n\n");
	putchar('\n');
      }
      free((void *)packet);
    }
}
