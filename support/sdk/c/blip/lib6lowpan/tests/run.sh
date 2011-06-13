#!/bin/sh

TESTS="test_bit_range_zero_p test_pack_tcfl test_pack_multicast test_pack_address \
       test_unpack_tcfl test_unpack_address \
       test_unpack_multicast test_unpack_ipnh test_unpack_udp test_pack_nhc_chain \
       test_inet_ntop6 test_ipnh_real_length test_iovec
"
 #      test_lowpan_frag_get" test_lowpan_pack_headers 

for T in $(echo $TESTS); do
    ./$T | grep -a tests
done

exit 0