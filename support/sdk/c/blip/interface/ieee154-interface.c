
#undef __BLOCKS__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <netinet/in.h>
#include <pthread.h>
#include <Ieee154.h>
#include <signal.h>

#include "serialsource.h"
#include "serialprotocol.h"
#include "sfsource.h"

#include "lib6lowpan/blip-pc-includes.h"
#include "lib6lowpan/lib6lowpan.h"
#include "lib6lowpan/iovec.h"

#include "tun_dev.h"
#include "logging.h"
#include "devconf.h"
#include "device-config.h"
#include "queue.h"

/* configuration about us */
struct config device_config;

/* packet sources */
int tun_fd;
serial_source ser_src;

/* reader-writer threads */
pthread_t pan_writer, tun_reader;
pthread_t pan_reader;
pthread_mutex_t pan_lock;

int write_pan_packet(uint8_t *buf, int len) {
  int rv;
  pthread_mutex_lock(&pan_lock); 
  rv = write_serial_packet(ser_src, buf, len); 
  pthread_mutex_unlock(&pan_lock);
  return rv;
}

void *read_pan_packet(int *len) {
  void *rv = NULL;
  fd_set fs;
/*   int fd = serial_source_fd(ser_src); */

/*   FD_ZERO(&fs); */
/*   FD_SET(fd, &fs); */

/*   pthread_mutex_lock(&pan_lock); */
/*   if (serial_source_empty(ser_src)) { */
/*     pthread_mutex_unlock(&pan_lock); */
/*     while (select(fd + 1, &fs, NULL, NULL, NULL) < 0) { */
/*       FD_ZERO(&fs); */
/*       FD_SET(fd, &fs); */
/*     } */
/*   } else { */
/*     pthread_mutex_unlock(&pan_lock); */
/*   } */

/*   pthread_mutex_lock(&pan_lock); */
/*   if (!serial_source_empty(ser_src)) { */
    rv = read_serial_packet(ser_src, len);
/*   } */
/*   pthread_mutex_unlock(&pan_lock); */
    return rv;
}

/* message queues for either direction... */
struct blocking_queue pan_q;
struct blocking_queue tun_q;


enum { N_RECONSTRUCTIONS = 30,
       RECONSTRUCT_CLEAN_INT = 5,};
struct lowpan_reconstruct reconstructions[N_RECONSTRUCTIONS];
pthread_t reconstruct_thread;
pthread_mutex_t reconstruct_lock;

enum {
  S_RUNNING,
  S_STOPPING,
};
sig_atomic_t run_state = S_RUNNING;


void stderr_msg(serial_source_msg problem) {
  // fprintf(stderr, "Note: %i\n", problem);
}

void *xmalloc(size_t sz) {
  void *rv = malloc(sz);
  if (rv) return rv;
  fatal("xmalloc: out of memory\n");
  exit (1);
}

int resolve_l2_addresses(struct ip6_packet *pkt, struct ieee154_frame_addr *fr) {
  char print_buf[128];

  memset(fr, 0, sizeof(struct ieee154_frame_addr));
  if (pkt->ip6_hdr.ip6_src.s6_addr16[0] == htons(0xfe80)) {
    fr->ieee_src.ieee_mode = IEEE154_ADDR_EXT;
    memcpy(fr->ieee_src.i_laddr.data, &pkt->ip6_hdr.ip6_src.s6_addr[8], 8);

    if (memcmp(fr->ieee_src.i_laddr.data, device_config.eui64.data, 8) != 0) {
      debug("wrong source address for link local communication, dropping\n");
      // ieee154_print(&fr->ieee_src, print_buf, 128);
      // debug("%s\n", print_buf);
      return -1;
    }
  } else {
    return -1;
  }

  if (pkt->ip6_hdr.ip6_dst.s6_addr16[0] == htons(0xfe80)) {
    if (pkt->ip6_hdr.ip6_dst.s6_addr16[5] == ntohs(0x00FF) &&
        pkt->ip6_hdr.ip6_dst.s6_addr16[6] == ntohs(0xFE00)) {

      if (ntohs(pkt->ip6_hdr.ip6_dst.s6_addr16[4]) == device_config.panid) {
        fr->ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;
        fr->ieee_dst.i_saddr = htole16(ntohs(pkt->ip6_hdr.ip6_dst.s6_addr16[7]));
      } else {
        warn("Cross-pan RFC4944 address mode not supported!\n");
        return -1;
      }
    } else {
      fr->ieee_dst.ieee_mode = IEEE154_ADDR_EXT;
      memcpy(fr->ieee_dst.i_laddr.data, &pkt->ip6_hdr.ip6_dst.s6_addr[8], 8);
    }

    ieee154_print(&fr->ieee_dst, print_buf, 128);
    debug("LL scope: L2 address is %s\n", print_buf);

  } else {
    return -1;
  }

  fr->ieee_dstpan = htole16(device_config.panid);
  return 0;
}

void init_reconstruct() {
  int i;
  memset(reconstructions, 0, sizeof(reconstructions));
  for (i = 0; i < N_RECONSTRUCTIONS; i++) {
    reconstructions[i].r_timeout = T_UNUSED;
    reconstructions[i].r_buf = NULL;
  }
  pthread_mutex_init(&reconstruct_lock, NULL);
}

struct lowpan_reconstruct *get_reconstruct(uint16_t key, uint16_t tag) {
  struct lowpan_reconstruct *ret = NULL;
  int i;
  for (i = 0; i < N_RECONSTRUCTIONS; i++) {
    struct lowpan_reconstruct *recon = &reconstructions[i];

    if (recon->r_tag == tag &&
        recon->r_source_key == key) {

      if (recon->r_timeout > T_UNUSED) {          
        recon->r_timeout = T_ACTIVE;
        ret = recon;
        goto done;

      } else if (recon->r_timeout < T_UNUSED) {
        // if we have already tried and failed to get a buffer, we
        // need to drop remaining fragments.
        ret = NULL;
        goto done;
      }
    }
    if (recon->r_timeout == T_UNUSED) {
      ret = recon;
    }
  }

 done:
  return ret;
}

void *age_reconstruct(void * arg) {
  time_t last_cleaning = time(NULL);

  while (run_state == S_RUNNING) {
    int i;
    if (last_cleaning > time(NULL) + RECONSTRUCT_CLEAN_INT) {
      pthread_mutex_lock(&reconstruct_lock);
      for (i = 0; i < N_RECONSTRUCTIONS; i++) {
        switch (reconstructions[i].r_timeout) {
        case T_ACTIVE:
          reconstructions[i].r_timeout = T_ZOMBIE; break; // age existing receptions
        case T_FAILED1:
          reconstructions[i].r_timeout = T_FAILED2; break; // age existing receptions
        case T_ZOMBIE:
        case T_FAILED2:
          // deallocate the space for reconstruction
          debug("timing out buffer: src: %i tag: %i\n", 
                reconstructions[i].r_source_key, reconstructions[i].r_tag);
          if (reconstructions[i].r_buf != NULL) {
            free(reconstructions[i].r_buf);
          }
          memset(&reconstructions[i], 0, sizeof(reconstructions[i]));
          reconstructions[i].r_timeout = T_UNUSED;
          reconstructions[i].r_buf = NULL;
          break;
        }
      }
      pthread_mutex_unlock(&reconstruct_lock);
    }
    sleep(1);
  } 
}

/* blocks until there's a new message for the pan.  then sends it out over the radio. */
void *pan_write(void * arg) {
  while (run_state == S_RUNNING) {
    int rv = -1;
    uint8_t *frame = queue_pop(&pan_q);
    
    /* the first byte is the dispatch value */
    /* the second byte is the length of the IEEE154 frame, not including the length byte */
    print_buffer(frame, frame[1] + 2);
    while (rv < 0) {
      rv = write_pan_packet(frame, frame[1] + 2);
      debug("pan_write: length: %i result: %i\n", frame[1] + 2, rv);
      // SDH : this isn't supposed to work with pthreads, and doesn't, at least on Linux
      // usleep(1e3);
    }
    free(frame);
  }
}

void deliver_to_kernel(struct lowpan_reconstruct *recon) {
  struct ip6_packet pkt;
  struct ip_iovec   v;
  struct ip6_hdr *iph = (struct ip6_hdr *)recon->r_buf;
  iph->ip6_plen = htons(recon->r_bytes_rcvd - sizeof(struct ip6_hdr));

  {
    struct ip6_ext *cur = (struct ip6_ext *)(recon->r_buf + sizeof(struct ip6_hdr));
    uint8_t nxt = iph->ip6_nxt;
    while (nxt == IPV6_HOP  || nxt == IPV6_ROUTING  || nxt == IPV6_FRAG ||
           nxt == IPV6_DEST || nxt == IPV6_MOBILITY || nxt == IPV6_IPV6) {
      nxt = cur->ip6e_nxt;
      cur = cur + cur->ip6e_len;
      if (cur->ip6e_len == 0) {
        break;
      }
    }
    if (nxt == IANA_UDP) {
      struct udp_hdr *udp = (struct udp_hdr *)cur;
      udp->len = htons(recon->r_bytes_rcvd - ((uint8_t *)cur - recon->r_buf));
    }
  }

  /* set up the IPv6 packet structure */
  memcpy(&pkt.ip6_hdr, iph, sizeof(struct ip6_hdr));
  pkt.ip6_data = &v;
  v.iov_base = recon->r_buf + sizeof(struct ip6_hdr);
  v.iov_len  = ntohs(iph->ip6_plen);
  v.iov_next = NULL;

  tun_write(tun_fd, &pkt);
  free(recon->r_buf);
  memset(recon, 0, sizeof(struct lowpan_reconstruct));
  recon->r_timeout = T_UNUSED;
  recon->r_buf = NULL;
}

void *pan_read(void * arg) {
  while (run_state == S_RUNNING) {
    struct packed_lowmsg lowmsg;
    struct ieee154_frame_addr frame_address;
    int length;
    uint8_t *frame = read_pan_packet(&length);
    uint8_t *buf = frame + 1;   /* skip the dispatch byte */

    if (!frame) 
      continue;

    if (frame[0] != TOS_SERIAL_802_15_4_ID) {
      warn("invalid frame received!\n");
      goto done;
    }

    info("serial packet arrived! (len: %i)\n", length);
    print_buffer(buf, length);

    buf     = unpack_ieee154_hdr(buf, &frame_address);
    length -= buf - frame;

    if (!buf) {
      warn("unpacking IEEE154 header failed!\n");
      goto done;
    }

    lowmsg.data = buf;
    lowmsg.len  = length;
    lowmsg.headers = getHeaderBitmap(&lowmsg);
    if (lowmsg.headers == LOWMSG_NALP) {
      warn("lowmsg NALP!\n");
      goto done;
    }

    if (hasFrag1Header(&lowmsg) || hasFragNHeader(&lowmsg)) {
      struct lowpan_reconstruct *recon;
      uint16_t tag, source_key;
      int rv;
      pthread_mutex_lock(&reconstruct_lock);

      source_key = ieee154_hashaddr(&frame_address.ieee_src);
      getFragDgramTag(&lowmsg, &tag);
      recon = get_reconstruct(source_key, tag);
      if (!recon) {
        pthread_mutex_unlock(&reconstruct_lock);
        goto done;
      }

      if (hasFrag1Header(&lowmsg))
        rv = lowpan_recon_start(&frame_address, recon, buf, length);
      else rv = lowpan_recon_add(recon, buf, length);

      if (rv < 0) {
        recon->r_timeout = T_FAILED1;
        pthread_mutex_unlock(&reconstruct_lock);
        goto done;
      } else {
        recon->r_timeout = T_ACTIVE;
        recon->r_source_key = source_key;
        recon->r_tag = tag;
      }

      if (recon->r_size == recon->r_bytes_rcvd) {
        deliver_to_kernel(recon);
      }
      pthread_mutex_unlock(&reconstruct_lock);

    } else {
      int rv;
      struct lowpan_reconstruct recon;

      buf = getLowpanPayload(&lowmsg);

      if ((rv = lowpan_recon_start(&frame_address, &recon, buf, length)) < 0) {
        warn("reconstruction failed!\n");
        goto done;
      }

      if (recon.r_size == recon.r_bytes_rcvd) {
        deliver_to_kernel(&recon);
      } else {
        free(recon.r_buf);
      }
    }

  done:
    free(frame);
  }
}

void *tun_dev_read(void * arg) {
  uint8_t buf[2500], read_buf[1500], *fragment;
  struct ip6_packet *packet = (struct ip6_packet *)buf;
  struct ip_iovec v;
  struct lowpan_ctx ctx;
  struct ieee154_frame_addr fr;
  int len, i;

  packet->ip6_data = &v;
  v.iov_next = NULL;
  v.iov_base = &buf[sizeof(struct ip6_packet)];
  ctx.tag = 0;

  while (run_state == S_RUNNING) {
    len = tun_read(tun_fd, read_buf, 1500);
    len -= sizeof(struct tun_pi);

    if (len < 0) {
      debug("tun_dev_read: read error\n");
      continue;
    }

    /* set up the ip6_packet structure */
    memcpy(&packet->ip6_hdr, read_buf + sizeof(struct tun_pi), len);

    v.iov_len = len;
    ctx.offset = 0;
    ctx.tag++;

    if (resolve_l2_addresses(packet, &fr) < 0) {
      debug("could not resolve next hop; dropping\n");
      continue;
    }

    fragment = xmalloc(128);
    /* PPDU : max length 127 (all inclusive) */
    /* 1 len + 2 FCS, so max buffer length is 126 (including length) */
    while ((len = lowpan_frag_get(&fragment[1], 126, packet, &fr, &ctx)) > 0) {
      fragment[0] = TOS_SERIAL_802_15_4_ID;
      fragment[1] = len - 1 + 2;

      print_buffer(fragment, len + 1);

      printf("PUSH: %i\n", queue_push(&pan_q, fragment));
      fragment = xmalloc(128);
    }
    free(fragment);
  }
}

void configure_setparams(struct config *c, int cmdno) {
  uint8_t buf[sizeof(config_cmd_t) + 1];
  config_cmd_t *cmd = (config_cmd_t *)(&buf[1]);
  int rv;
  memset(buf, 0, sizeof(buf));
  buf[0] = TOS_SERIAL_DEVCONF;

  cmd->cmd = cmdno;
  cmd->rf.short_addr = 12;// c->router_addr.s6_addr16[7]; // is network byte-order
  cmd->rf.lpl_interval = htons(c->lpl_interval);
  cmd->rf.channel = c->channel;
  cmd->retx.retries = htons(c->retries);
  cmd->retx.delay = htons(c->delay);

  rv = write_pan_packet(buf, CONFIGURE_MSG_SIZE + 1);
  debug("configure result: %i\n", rv);
}

/* 
 * At startup, set the L2 properties of the attached device, and read
 * back the EUI-64.  We'll need that to form the link-local address.
 */
int setup_serial(char *device, char *rate, struct config *c) {
  uint8_t *ser_data;
  int      ser_len = 0;
  config_reply_t *reply;
  /* open the serial source as blocking */
  ser_src = open_serial_source(device, platform_baud_rate(rate), 0, stderr_msg);
  if (!ser_src) return -1;

  /* kill ourselves if anything hangs */
  alarm(5);

  /* set the parameters */
  configure_setparams(c, CONFIG_REBOOT);

  /* wait to hear back... */
  ser_data = read_serial_packet(ser_src, &ser_len);
  if (!ser_data) return -1;
  free(ser_data);

  configure_setparams(c, CONFIG_SET_PARM);
  ser_data = read_serial_packet(ser_src, &ser_len);

  if (ser_data[0] != TOS_SERIAL_DEVCONF) return -1;
  reply = (config_reply_t *)&ser_data[1];
  memcpy(c->eui64.data, reply->ext_addr, 8);

  free(ser_data);
  alarm(0);

  return 0;
}



int main(int argc, char **argv) {
  char     print_buf[128], dev[IF_NAMESIZE];

  log_init();
  log_setlevel(LOGLVL_DEBUG);

  if (argc != 3) {
    fatal("%s <device> <rate>\n", argv[0]);
    exit(1);
  }

  queue_init(&pan_q);
  queue_init(&tun_q);
  init_reconstruct();
  
  if (config_parse("ieee154_interface.conf", &device_config)) {
    log_fatal_perror("parsing config file failed");
    exit(1);
  }

  /* set up the serial interface device */
  pthread_mutex_init(&pan_lock, NULL);
  if (setup_serial(argv[1], argv[2], &device_config)) {
    fatal("opening serial device failed!\n");
    exit(1);
  }

  snprintf(print_buf, 128, "%02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x", 
           device_config.eui64.data[0],device_config.eui64.data[1],device_config.eui64.data[2],
           device_config.eui64.data[3],device_config.eui64.data[4],device_config.eui64.data[5],
           device_config.eui64.data[6],device_config.eui64.data[7]);
  info("device EUI-64: %s\n", print_buf);

  pthread_create(&pan_writer, NULL, pan_write, NULL);
  pthread_create(&reconstruct_thread, NULL, age_reconstruct, NULL);

  /* initialize thes tun */
  tun_fd = tun_open(dev);
  if (tun_fd < 0) {
    log_fatal_perror("opening tun device failed");
    exit(1);
  }

  if (tun_setup(dev, device_config.eui64) < 0) {
    exit(1);
  }

  sleep(1);
  pthread_create(&tun_reader, NULL, tun_dev_read, NULL);
  pthread_create(&pan_reader, NULL, pan_read, NULL);
  
  pthread_join(pan_writer, NULL);
}
