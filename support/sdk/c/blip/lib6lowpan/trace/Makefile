
EXTRA=../utility.c
EXTRA_O=$(EXTRA:.c=.o) ../lib6lowpan.a

CFLAGS += -I.. -I../.. -I$(TOSROOT)/tos/types -DPC -DHAVE_CONFIG_H

decompress: decompress.o $(EXTRA_O)
	$(CC) -o $@ decompress.o $(EXTRA_O)

clean:
	rm -rf *.o decompress
