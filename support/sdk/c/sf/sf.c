#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>

#include "sfsource.h"
#include "serialsource.h"

serial_source src;
int server_socket;
int packets_read, packets_written, num_clients;

struct client_list
{
  struct client_list *next;
  int fd;
} *clients;

int unix_check(const char *msg, int result)
{
  if (result < 0)
    {
      perror(msg);
      exit(2);
    }

  return result;
}

void *xmalloc(size_t s)
{
  void *p = malloc(s);

  if (!p)
    {
      fprintf(stderr, "out of memory\n");
      exit(2);
    }
  return p;
}

void fd_wait(fd_set *fds, int *maxfd, int fd)
{
  if (fd > *maxfd)
    *maxfd = fd;
  FD_SET(fd, fds);
}

void pstatus(void)
{
  printf("clients %d, read %d, wrote %d\n", num_clients, packets_read,
	 packets_written);
}

void forward_packet(const void *packet, int len);


void add_client(int fd)
{
  struct client_list *c = xmalloc(sizeof *c);

  c->next = clients;
  clients = c;
  num_clients++;
  pstatus();

  c->fd = fd;
}

void rem_client(struct client_list **c)
{
  struct client_list *dead = *c;

  *c = dead->next;
  num_clients--;
  pstatus();
  close(dead->fd);
  free(dead);
}

void new_client(int fd)
{
  fcntl(fd, F_SETFL, 0);
  if (init_sf_source(fd) < 0)
    close(fd);
  else
    add_client(fd);
}

void check_clients(fd_set *fds)
{
  struct client_list **c;

  for (c = &clients; *c; )
    {
      int next = 1;

      if (FD_ISSET((*c)->fd, fds))
	{
	  int len;
	  const void *packet = read_sf_packet((*c)->fd, &len);

	  if (packet)
	    {
	      forward_packet(packet, len);
	      free((void *)packet);
	    }
	  else
	    {
	      rem_client(c);
	      next = 0;
	    }
	}
      if (next)
	c = &(*c)->next;
    }
}

void wait_clients(fd_set *fds, int *maxfd)
{
  struct client_list *c;

  for (c = clients; c; c = c->next)
    fd_wait(fds, maxfd, c->fd);
}

void dispatch_packet(const void *packet, int len)
{
  struct client_list **c;

  for (c = &clients; *c; )
    if (write_sf_packet((*c)->fd, packet, len) >= 0)
      c = &(*c)->next;
    else
      rem_client(c);
}

void open_server_socket(int port)
{
  struct sockaddr_in me;
  int opt;

  server_socket = unix_check("socket", socket(AF_INET, SOCK_STREAM, 0));
  unix_check("socket", fcntl(server_socket, F_SETFL, O_NONBLOCK));
  memset(&me, 0, sizeof me);
  me.sin_family = AF_INET;
  me.sin_port = htons(port);

  opt = 1;
  unix_check("setsockopt", setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR,
				     (char *)&opt, sizeof(opt)));
                                                                           
  unix_check("bind", bind(server_socket, (struct sockaddr *)&me, sizeof me));
  unix_check("listen", listen(server_socket, 5));
}

void check_new_client(void)
{
  int clientfd = accept(server_socket, NULL, NULL);

  if (clientfd >= 0)
    new_client(clientfd);
}





void stderr_msg(serial_source_msg problem)
{
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

  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

void open_serial(const char *dev, int baud)
{
    char ldev[80]; 
#ifdef __CYGWIN__
    int portnum;
    if (strncasecmp(dev, "COM", 3) == 0)
      {
	fprintf(stderr, "Warning: you're attempting to open a Windows rather that a Cygwin device.  Retrying with "); 
	portnum=atoi(dev+3);
	sprintf(ldev, "/dev/ttyS%d",portnum-1);
	fprintf(stderr,ldev);
	fprintf(stderr, "\n");
      } 
    else
#endif
    strcpy(ldev, dev); 

  src = open_serial_source(ldev, baud, 1, stderr_msg);
  if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%d\n", dev, baud);
      exit(1);
    }
}

void check_serial(void)
{
  int len;
  const unsigned char *packet = read_serial_packet(src, &len);

  if (packet)
    {
      packets_read++;
      dispatch_packet(packet, len);
      free((void *)packet);
    }
}

void forward_packet(const void *packet, int len)
{
  int ok = write_serial_packet(src, packet, len);

  packets_written++;
  if (ok < 0)
    exit(2);
  if (ok > 0)
    fprintf(stderr, "Note: write failed\n");
}

int main(int argc, char **argv)
{
  int serfd;

  if (argc != 4)
    {
      fprintf(stderr,
	      "Usage: %s <port> <device> <rate> - act as a serial forwarder on <port>\n"
	      "(listens to serial port <device> at baud rate <rate>)\n" ,
	      argv[0]);
      exit(2);
    }

  if (signal(SIGPIPE, SIG_IGN) == SIG_ERR)
    fprintf(stderr, "Warning: failed to ignore SIGPIPE.\n");

  open_serial(argv[2], platform_baud_rate(argv[3]));
  serfd = serial_source_fd(src);
  open_server_socket(atoi(argv[1]));

  for (;;)
    {
      fd_set rfds;
      int maxfd = -1;
      struct timeval zero;
      int serial_empty;
      int ret;

      zero.tv_sec = zero.tv_usec = 0;

      FD_ZERO(&rfds);
      fd_wait(&rfds, &maxfd, serfd);
      fd_wait(&rfds, &maxfd, server_socket);
      wait_clients(&rfds, &maxfd);

      serial_empty = serial_source_empty(src);
      if (serial_empty)
	ret = select(maxfd + 1, &rfds, NULL, NULL, NULL);
      else
	{
	  ret = select(maxfd + 1, &rfds, NULL, NULL, &zero);
	  check_serial();
	}
      if (ret >= 0)
	{
	  if (FD_ISSET(serfd, &rfds))
	    check_serial();

	  if (FD_ISSET(server_socket, &rfds))
	    check_new_client();

	  check_clients(&rfds);
	}
    }
}
