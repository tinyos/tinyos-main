
GCC=gcc
CFLAGS=-I../include -I../driver/ -DPC -g -Wall


all: test_client test_server

test_circ: test_circ.c circ.c circ.h
	$(GCC) -o $@ $^ $(CFLAGS)

test_client: test_client.c  # tcplib.h tcplib.c circ.c
	$(GCC) -o $@ $< $(CFLAGS)
# 	$(GCC) -o $@ $< tcplib.c circ.c ../driver/tun_dev.c ../lib6lowpan/ip_malloc.c ../lib6lowpan/in_cksum.c $(CFLAGS)

test_server: test_server.c  tcplib.h tcplib.c circ.c
	$(GCC) -o $@ $< tcplib.c circ.c ../driver/tun_dev.c ../lib6lowpan/ip_malloc.c ../lib6lowpan/in_cksum.c $(CFLAGS)

clean:
	rm -rf test_server test_circ

