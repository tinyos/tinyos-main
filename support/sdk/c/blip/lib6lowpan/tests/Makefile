
CFLAGS=-U__BLOCKS__ -DPC -DUNIT_TESTING -g -I../../../../../../tos/types -I.. -I../../ -DHAVE_CONFIG_H
LIBSOURCE=../lib6lowpan.c ../lib6lowpan_4944.c ../lib6lowpan_frag.c \
	../iovec.c ../utility.c ../in_cksum.c
LIB=../lib6lowpan.a
LIB_CONTEXT=../lib6lowpan.a context.o

TARGETS=test_bit_range_zero_p test_pack_tcfl test_pack_multicast test_pack_address \
	test_unpack_tcfl test_unpack_address \
	test_unpack_multicast test_unpack_ipnh test_unpack_udp test_pack_nhc_chain \
	test_lowpan_frag_get test_inet_ntop6 test_ipnh_real_length test_iovec
#	test_lowpan_pack_headers

all: $(TARGETS)

check:
	./run.sh

clean:
	rm -f $(TARGETS) *.o

distclean: clean

test_bit_range_zero_p: test_bit_range_zero_p.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_pack_tcfl: test_pack_tcfl.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_pack_multicast: test_pack_multicast.c $(LIB_CONTEXT) 

test_pack_address: test_pack_address.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_lowpan_pack_headers: test_lowpan_pack_headers.c $(LIB)
	$(CC) -o $@ $(CFLAGS) $< $(LIB) -DHAVE_LOWPAN_EXTERN_MATCH_CONTEXT

test_unpack_tcfl: test_unpack_tcfl.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_unpack_address: test_unpack_address.c $(LIB)
	$(CC) -o $@ $(CFLAGS) $< $(LIB) -DHAVE_LOWPAN_EXTERN_MATCH_CONTEXT

test_unpack_multicast: test_unpack_multicast.c $(LIB)
	$(CC) -o $@ $(CFLAGS) $< $(LIB) -DHAVE_LOWPAN_EXTERN_MATCH_CONTEXT

test_unpack_ipnh: test_unpack_ipnh.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_unpack_udp: test_unpack_udp.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_pack_nhc_chain: test_pack_nhc_chain.c $(LIB_CONTEXT)
	$(CC) -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_lowpan_frag_get: test_lowpan_frag_get.o $(LIB)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB) -DHAVE_LOWPAN_EXTERN_MATCH_CONTEXT

test_in_cksum: test_in_cksum.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_lowpan_recon_start: test_lowpan_recon_start.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_lowpan_unpack_headers: test_lowpan_unpack_headers.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_inet_ntop6: test_inet_ntop6.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_ipnh_real_length: test_ipnh_real_length.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

test_iovec: test_iovec.o $(LIB_CONTEXT)
	$(CC)  -o $@ $(CFLAGS) $< $(LIB_CONTEXT) 

.c.o:
	$(CC) -c -o $@ $< $(CFLAGS)


