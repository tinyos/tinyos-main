

#include <Windows.h>
#include <stdio.h>
#include <string.h>
#include <ddk/ntddk.h>
#include <stdint.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>

#define AF_INET6 23
#include <ip.h>
#include <in_cksum.h>

/* tun defs we'll need. */
#define ADAPTER_KEY "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
#define NETWORK_CONNECTIONS_KEY "SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
#define TAP_ID "tap0901"
#define TAP_COMPONENT_ID TAP_ID

#define USERMODEDEVICEDIR "\\\\.\\Global\\"
#define TAPSUFFIX         ".tap"

#define TAP_CONTROL_CODE(request,method) \
  CTL_CODE (FILE_DEVICE_UNKNOWN, request, method, FILE_ANY_ACCESS)
#define TAP_IOCTL_GET_VERSION           TAP_CONTROL_CODE (2, METHOD_BUFFERED)
#define TAP_IOCTL_SET_MEDIA_STATUS      TAP_CONTROL_CODE (6, METHOD_BUFFERED)

struct tap_reg {
  const char *guid;
  struct tap_reg *next;
};

struct panel_reg {
  char *name;
  char *guid;
  struct panel_reg *next;
};

/* define what is usuall in if_ether.h */
#define ETH_ALEN 6
#define ETH_P_IPV6 0x86DD
#define IPPROTO_ICMPV6 58

/* 802.3 ethernet header: not provided in cygwin */
struct ethhdr {
  unsigned char  h_dest[ETH_ALEN];
  unsigned char  h_source[ETH_ALEN];
  unsigned short h_proto;
} __attribute__((packed));

/* link-layer address ICMPv6 option header */
struct icmp6_llopt_hdr {
  uint8_t type;
  uint8_t len;
  uint8_t ll_addr[ETH_ALEN];
} __attribute__((packed));

/* for a given device id, look up the device GUID in the registry. */
char *get_tap_guid (int i) {
  static char guid[256];
  char *rv = NULL;
  HKEY adapter_key;
  LONG status;
  DWORD len;
  struct tap_reg *first = NULL;
  struct tap_reg *last = NULL;

  status = RegOpenKeyEx(HKEY_LOCAL_MACHINE,
			ADAPTER_KEY,
			0,
			KEY_READ,
			&adapter_key);

  if (status != ERROR_SUCCESS)
    printf ("Error opening registry key: %s", ADAPTER_KEY);

  do {
    char enum_name[256];
    char unit_string[256];
    HKEY unit_key;
    char component_id_string[] = "ComponentId";
    char component_id[256];
    char net_cfg_instance_id_string[] = "NetCfgInstanceId";
    char net_cfg_instance_id[256];
    char name_data[256];
    DWORD name_type;
    const char name_string[] = "Name";

    DWORD data_type;

    len = sizeof (enum_name);
    status = RegEnumKeyEx(adapter_key,
                          i,
                          enum_name,
                          &len,
                          NULL,
                          NULL,
                          NULL,
                          NULL);
    if (status == ERROR_NO_MORE_ITEMS)
      break;
    else if (status != ERROR_SUCCESS)
      printf ("Error enumerating registry subkeys of key: %s\n",
              ADAPTER_KEY);

    snprintf (unit_string, sizeof(unit_string), "%s\\%s",
              ADAPTER_KEY, enum_name);

    status = RegOpenKeyEx(HKEY_LOCAL_MACHINE,
                          unit_string,
                          0,
                          KEY_READ,
                          &unit_key);

    if (status != ERROR_SUCCESS)
      printf("Error opening registry key: %s\n", unit_string);
    else
      {
        len = sizeof (component_id);

        status = RegQueryValueEx(unit_key,
                                 component_id_string,
                                 NULL,
                                 &data_type,
                                 component_id,
				   &len);

        if (status != ERROR_SUCCESS || data_type != REG_SZ)
/*           printf("Error opening registry key (2): %s : %s\n", */
/* 		 unit_string, component_id); */
          ;
        else
          {	      
            len = sizeof (net_cfg_instance_id);
            status = RegQueryValueEx(unit_key,
                                     net_cfg_instance_id_string,
                                     NULL,
                                     &data_type,
                                     net_cfg_instance_id,
                                     &len);
            
            if (status == ERROR_SUCCESS && data_type == REG_SZ)
              {
                if (!strcmp (component_id, TAP_COMPONENT_ID))
                  {
                    len = sizeof (name_data);
                    status = RegQueryValueEx(unit_key,
                                             name_string,
                                             NULL,
                                             &name_type,
                                             name_data,
                                             &len);


                    printf("guid: %s %S\n", net_cfg_instance_id, name_data);
                    strncpy(guid, net_cfg_instance_id, sizeof(guid));
                    rv = guid;
                  }
              }
          }
        RegCloseKey (unit_key);
      }
  } while (0);
    
  RegCloseKey (adapter_key);
  return rv;
}

/* get a list of all the devices registered in the control pannel
 * we need this to get the guid/name pairs.
 */
struct panel_reg *get_panel_reg () {
  LONG status;
  HKEY network_connections_key;
  DWORD len;
  struct panel_reg *first = NULL;
  struct panel_reg *last = NULL;
  int i = 0;

  status = RegOpenKeyEx(HKEY_LOCAL_MACHINE,
			NETWORK_CONNECTIONS_KEY,
			0,
			KEY_READ,
			&network_connections_key);

  if (status != ERROR_SUCCESS)
    printf("Error opening registry key: %s", NETWORK_CONNECTIONS_KEY);

  while (1) {
      char enum_name[256];
      char connection_string[256];
      HKEY connection_key;
      char name_data[256];
      DWORD name_type;
      const char name_string[] = "Name";

      len = sizeof (enum_name);
      status = RegEnumKeyEx(network_connections_key,
			    i,
			    enum_name,
			    &len,
			    NULL,
			    NULL,
			    NULL,
			    NULL);
      if (status == ERROR_NO_MORE_ITEMS)
	break;
      else if (status != ERROR_SUCCESS)
	printf("Error enumerating registry subkeys of key: %s",
	     NETWORK_CONNECTIONS_KEY);

      snprintf (connection_string, sizeof(connection_string),
                "%s\\%s\\Connection",
                NETWORK_CONNECTIONS_KEY, enum_name);

      status = RegOpenKeyEx(HKEY_LOCAL_MACHINE,
			    connection_string,
			    0,
			    KEY_READ,
			    &connection_key);

      if (status != ERROR_SUCCESS)
	printf("Error opening registry key: %s", connection_string);
      else
	{
	  len = sizeof (name_data);
	  status = RegQueryValueEx(
				   connection_key,
				   name_string,
				   NULL,
				   &name_type,
				   name_data,
				   &len);

	  if (status != ERROR_SUCCESS || name_type != REG_SZ)
	    printf( "Error opening registry key: %s\\%s\\%s",
                    NETWORK_CONNECTIONS_KEY, connection_string, name_string);
	  else
	    {
	      struct panel_reg *reg;
              reg = malloc(sizeof(struct panel_reg));
	      reg->name = malloc(strlen(name_data));
	      reg->guid = malloc(strlen(enum_name));
              strcpy(reg->name, name_data);
              strcpy(reg->guid, enum_name);
		      
	      /* link into return list */
	      if (!first)
		first = reg;
	      if (last)
		last->next = reg;
	      last = reg;
	    }
	  RegCloseKey (connection_key);
	}
      ++i;
    }

  RegCloseKey (network_connections_key);

  return first;
}

/* Open a particular GUID and return a handle to it.
 */
HANDLE open_tun(char *guid, int guid_len) {
  HANDLE hand = NULL;;
  LONG status;
  DWORD len;
  int device_number;
  char device_path[256];

  for (device_number = 0; device_number < 100; device_number ++) {
    char *device_guid = get_tap_guid(device_number);
    
    if (device_guid) {
      printf("%i: %s\n", device_number, device_guid);
      if (guid) 
        strncpy(guid, device_guid, guid_len);
    } else {
      continue;
    }

    /* Open Windows TAP-Win32 adapter */
    snprintf (device_path, sizeof(device_path), "%s%s%s",
              USERMODEDEVICEDIR,
              device_guid,
              TAPSUFFIX);

    hand = CreateFile (device_path,
                       GENERIC_READ | GENERIC_WRITE,
                       0, /* was: FILE_SHARE_READ */
                       0,
                       OPEN_EXISTING,
                       FILE_ATTRIBUTE_SYSTEM, //  | FILE_FLAG_OVERLAPPED,
                       0);
    
    if (hand == INVALID_HANDLE_VALUE) {
      hand = NULL;
      printf("CreateFile failed on TAP device: %s\n", device_path);
    } else
      break;
    
    device_number++;
  }
  if (hand) {
    unsigned long info[3] = {0, 0, 0};
    DeviceIoControl(hand, 
                    TAP_IOCTL_GET_VERSION, 
                    &info, 
                    sizeof(info),
                    &info,
                    sizeof(info),
                    &len,
                    NULL);

    if (info[0] < 9 || (info[0] == 9 && info[1] < 6)) {
      printf("version: %i.%i.%i\n", info[0], info[1], info[2]);
      printf("the driver has only been tested with version 9.6.0\n");
      printf("aborting\n");
      return NULL;
    }


    status = 1;
    DeviceIoControl(hand, 
                    TAP_IOCTL_SET_MEDIA_STATUS, 
                    &status, 
                    sizeof(status), 
                    &status, 
                    sizeof(status), 
                    &len, 
                    NULL);

  }

  return hand;
}

/* Send an ICMPv6 Neighbor Advertisement in response to the NS stored
   in read_buf */
int send_icmp6_na(HANDLE h, char *read_buf) {
  // incomming message
  struct ethhdr *eh;
  struct ip6_hdr *iph;
  struct icmp6_hdr *icmph;
  uint32_t *pad;
  struct in6_addr *target;


  // outgoing message
  unsigned char m_buf[1280];
  struct ethhdr *r_eh = (struct ethhdr *)m_buf;
  struct ip6_hdr *r_iph = (struct ip6_hdr *)(r_eh + 1);
  struct icmp6_hdr *r_icmph = (struct icmp6_hdr *)(r_iph + 1);
  uint8_t *r_opt = (uint8_t *)(r_icmph + 1);
  struct in6_addr *r_target = (struct in6_addr *)(r_opt + 4);
  struct icmp6_llopt_hdr *r_llopt = (struct icmp6_llopt_hdr *)(r_target + 1);
  vec_t cksum_vec[7];
  uint32_t hdr[2];

  DWORD len;

  eh = (struct ethhdr *)read_buf;
  iph = (struct ip6_hdr *)(eh + 1);
  icmph = (struct icmp6_hdr *)(iph + 1);
  pad = (uint32_t *)(icmph + 1);
  target = (struct in6_addr *)(pad + 1);

  // ethernet header
  memcpy(r_eh->h_dest, eh->h_source, ETH_ALEN);
  memcpy(r_eh->h_source, &target->s6_addr[8], 3);
  memcpy(&r_eh->h_source[3], &target->s6_addr[13], 3);
  r_eh->h_source[0] |= 0x2;
  r_eh->h_proto = htons(ETH_P_IPV6);

  // ip6 header
  memset(r_iph, 0, sizeof(struct ip6_hdr));
  r_iph->vlfc[0] = 6 << 4;
  r_iph->plen = htons(sizeof(struct icmp6_hdr) + 4 +
                      sizeof(struct in6_addr) + sizeof(struct icmp6_llopt_hdr));
  r_iph->nxt_hdr = IPPROTO_ICMPV6;
  r_iph->hlim = 255;
  memcpy(r_iph->ip6_src.s6_addr, target->s6_addr, 16);
  memcpy(r_iph->ip6_dst.s6_addr, iph->ip6_src.s6_addr, 16);
  
  // icmp6_hdr
  r_icmph->type = ICMP_TYPE_NEIGHBOR_ADV;
  r_icmph->code = 0;
  r_icmph->cksum = 0;
  memset(r_opt, 0, 4);
  // set override, solicited flags
  r_opt[0] = 0x60;

  // target
  memcpy(r_target->s6_addr, r_iph->ip6_src.s6_addr, 16);

  // include target LL addr opt.
  r_llopt->type = 2;
  r_llopt->len = 1;
  memcpy(r_llopt->ll_addr, r_eh->h_source, ETH_ALEN);
  
  // fill in checksum
  cksum_vec[0].ptr = (uint8_t *)(r_iph->ip6_src.s6_addr);
  cksum_vec[0].len = 16;
  cksum_vec[1].ptr = (uint8_t *)(r_iph->ip6_dst.s6_addr);
  cksum_vec[1].len = 16;
  cksum_vec[2].ptr = (uint8_t *)hdr;
  cksum_vec[2].len = 8;
  hdr[0] = htonl(ntohs(r_iph->plen));
  hdr[1] = htonl(IPPROTO_ICMPV6);
  cksum_vec[3].ptr = (uint8_t *)r_icmph;
  cksum_vec[3].len = ntohs(r_iph->plen);
  r_icmph->cksum = htons(in_cksum(cksum_vec, 4));
      
  WriteFile(h, m_buf, ntohs(r_iph->plen) + sizeof(struct ip6_hdr) + sizeof(struct ethhdr), &len, NULL);
}

HANDLE tun_handle;
int tun_pipe[2];
struct panel_reg *my_device, *device_list;
unsigned char host_mac[ETH_ALEN];

DWORD WINAPI tun_forward(LPVOID arg) {
  char read_buf[1500];
  uint32_t u_len;
  DWORD len;

  while (1) {
    struct ethhdr *eh;
    struct ip6_hdr *iph;
    struct icmp6_hdr *icmph;
    int i;

    ReadFile(tun_handle, read_buf, 1500, &len, NULL);
    eh = (struct ethhdr *)read_buf;
    iph = (struct ip6_hdr *)(eh + 1);
    icmph = (struct icmp6_hdr *)(iph + 1);

    if (eh->h_proto == htons(ETH_P_IPV6)) {
      if (iph->nxt_hdr == IPPROTO_ICMPV6) {
        if (icmph->type == ICMP_TYPE_NEIGHBOR_SOL) {

          if (iph->ip6_src.s6_addr32[0] == 0 &&
              iph->ip6_src.s6_addr32[1] == 0 &&
              iph->ip6_src.s6_addr32[2] == 0 &&
              iph->ip6_src.s6_addr32[3] == 0) {
            // ignore DAD NS's
            continue;
          }

          if (iph->ip6_dst.s6_addr[15] == 0x64)
            continue;

          memcpy(host_mac, eh->h_source, ETH_ALEN);
          send_icmp6_na(tun_handle, read_buf);
        }
      }
      // only forward IPv6, non-ICMP messages
      u_len = len - sizeof(struct ethhdr);
      write(tun_pipe[1], &u_len, 4);
      write(tun_pipe[1], iph, u_len);
    }
  }
}


int tun_open(char *dev) {
  struct panel_reg *q;
  char guid[256];
  tun_handle = open_tun(guid, 256);
  DWORD len;

  if (dev) {
    *dev = '\0';
  }
  device_list = get_panel_reg();
  for (q = device_list; q != NULL; q = q->next) {
    if (!strcmp(q->guid, guid)) {
      printf("%s %s\n", q->guid, q->name);
      break;
    }
  }

  my_device = q;
  if (tun_handle == NULL || q == NULL) return -1;

  if (pipe(tun_pipe) < 0)
    return -1;

  return tun_pipe[0];

}


int tun_setup(char *dev, struct in6_addr *addr, int pfxlen) {
  char system_buf[256], ip_buf[256];
  inet_ntop6(addr, ip_buf, 256);

  if (!tun_handle) return -1;

  snprintf(system_buf, 
           256, 
           "netsh interface ipv6 add address \"%s\" %s", 
           my_device->name,
           ip_buf);
  system(system_buf);

/*   if (fcntl(tun_pipe[0], F_SETFL, O_NONBLOCK) < 0) { */
/*     perror("O_NONBLOCK"); */
/*   } */

  CreateThread(NULL, 0, tun_forward, NULL, 0, NULL);

  return 0;
}

int tun_write(int fd, struct split_ip_msg *msg) {
  uint8_t buf[INET_MTU + sizeof(struct ethhdr)], *packet;
  struct ethhdr *eh = (struct ethhdr *)buf;
  struct generic_header *cur;
  packet = (uint8_t *)(eh + 1);
  DWORD write_len;

  if (ntohs(msg->hdr.plen) + sizeof(struct ip6_hdr) >= INET_MTU)
    return -1;

  memcpy(eh->h_source, host_mac, ETH_ALEN);
  memcpy(eh->h_source, &msg->hdr.ip6_src.s6_addr[8], 3);
  memcpy(&eh->h_source[3], &msg->hdr.ip6_src.s6_addr[13], 3);
  eh->h_source[0] |= 0x2;
  eh->h_proto = htons(ETH_P_IPV6);

  memcpy(packet, &msg->hdr, sizeof(struct ip6_hdr));
  packet += sizeof(struct ip6_hdr);

  cur = msg->headers;
  while (cur != NULL) {
    memcpy(packet, cur->hdr.data, cur->len);
    packet += cur->len;
    cur = cur->next;
  }

  memcpy(packet, msg->data, msg->data_len);

  if (WriteFile(tun_handle, buf, sizeof(struct ethhdr) + sizeof(struct ip6_hdr) + ntohs(msg->hdr.plen), 
                &write_len, NULL))
    return 0;
  else 
    return -1;
}

int tun_read(int fd, char *buf, int len) {
  uint32_t pkt_len, current_read = 0;
  int read_len;
  read_len = read(fd, &pkt_len, 4);
  
  if (read_len <= 0) {
    return 0;
  } else if (read_len != 4) {
    printf("SHORT READ: %i!\n", read_len);
    return 0;
  }

  if (pkt_len > len) {
    printf("NOT ENOUGH BUFFER\n");
    return 0;
  }

  while (current_read < pkt_len) {
    current_read += read(fd, buf + current_read, pkt_len - current_read);
  }
  return current_read;
}

int main() {
  int tun_fd;
  struct in6_addr l_addr;
  char buf[1500];
  inet_pton6("fec0::64", &l_addr);
  tun_fd = tun_open(NULL);
  tun_setup(NULL, &l_addr, 64);

  while (1) {
    uint32_t len, i;
    len = tun_read(tun_fd, buf, 1500);
    printf("read: len: %i\n", len);
    for (i = 0; i < len; i++) {
      printf("%hhx ", buf[i]);
    }
    printf("\n");
 
  }
}

