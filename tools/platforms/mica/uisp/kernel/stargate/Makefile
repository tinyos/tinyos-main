# Comment/uncomment the following line to enable/disable debugging
#DEBUG = y

# This Makefile has been simplified as much as possible, by putting all
# generic material, independent of this specific directory, into
# ../Rules.make. Read that file for details

KERNELDIR = /home/pbuonado/Projects/stargate-linux/linux-2.4.19-star5

CFLAGS = -v -O2
CFLAGS += -I. -I$(KERNELDIR)/include
CFLAGS += -DEXPORT_SYMTAB

CC=arm-linux-gcc

all: stargate_ssp.o

stargate_ssp.o: stargate_ssp.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o *~ core
