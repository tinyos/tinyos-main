COMPONENT=TestNetworkAppC

CFLAGS += -I$(TINYOS_OS_DIR)/lib/net \
          -I$(TINYOS_OS_DIR)/lib/net/drip \
          -I$(TINYOS_OS_DIR)/lib/net/4bitle \
          -I$(TINYOS_OS_DIR)/lib/net/ctp #-DNO_DEBUG

TFLAGS += -I$(TINYOS_OS_DIR)/../apps/tests/TestDissemination \
          -I$(TINYOS_OS_DIR)/../support/sdk/c \
          -I$(TINYOS_OS_DIR)/types \
          -I.

LIBMOTE = $(TINYOS_OS_DIR)/../support/sdk/c/libmote.a
LISTEN_OBJS = collection_msg.o test_network_msg.o tn-listener.o $(LIBMOTE)
INJECT_OBJS = set_rate_msg.o tn-injector.o collection_debug_msg.o $(LIBMOTE)

# arguments: output filename stem, input filename, struct name
define mig_templ
TOSMAKE_CLEAN_EXTRA += $(1).c $(1).h $(1).java $(1).o
$(1).c:
	nescc-mig -o $(1).h c $$(NESC_PFLAGS) $$(CFLAGS) $$(TFLAGS) $(2) $(3)
$(1).java:
	nescc-mig -o $(1).java java $$(NESC_PFLAGS) $$(CFLAGS) $$(TFLAGS) -java-classname=$(3) $(2) $(3)
endef

%.o: %.c
	gcc $(TFLAGS) $(CFLAGS) -c -o $@ $<

tn-listener: $(LISTEN_OBJS)
	gcc -v $(TFLAGS) $(CFLAGS) -o $@ $(LISTEN_OBJS)

tn-injector: $(INJECT_OBJS)
	gcc $(TFLAGS) $(CFLAGS) -o $@ $(INJECT_OBJS)

tn-injector.o: tn-injector.c test_network_msg.c
	gcc $(TFLAGS) $(CFLAGS) -c -o $@ $<

#test_network_msg.c:
#	mig -o test_network_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) TestNetwork.h TestNetworkMsg

#set_rate_msg.c:
#	mig -o set_rate_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TINYOS_OS_DIR)/lib/net/DisseminationEngine.h dissemination_message

#set_rate_msg.o: set_rate_msg.c
#	gcc $(CFLAGS) $(TFLAGS) -c -o $@ $<

#test_network_msg.o: test_network_msg.c
#	gcc $(CFLAGS) $(TFLAGS) -c -o $@ $<

#collection_msg.c:
#	mig -o collection_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TINYOS_OS_DIR)/lib/net/collection/ForwardingEngine.h collection_header

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

$(eval $(call mig_templ,test_network_msg,TestNetwork.h,TestNetworkMsg))
$(eval $(call mig_templ,set_rate_msg,$(TINYOS_OS_DIR)/lib/net/drip/DisseminationEngine.h,dissemination_message))
$(eval $(call mig_templ,collection_debug_msg,$(TINYOS_OS_DIR)/lib/net/CollectionDebugMsg.h,CollectionDebugMsg))
