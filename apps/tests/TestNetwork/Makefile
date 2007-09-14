COMPONENT=TestNetworkAppC

CFLAGS += -I$(TOSDIR)/lib/net \
          -I$(TOSDIR)/lib/net/drip \
          -I$(TOSDIR)/lib/net/le \
          -I$(TOSDIR)/lib/net/ctp #-DNO_DEBUG

TFLAGS += -I$(TOSDIR)/../apps/tests/TestDissemination \
          -I$(TOSDIR)/../support/sdk/c \
          -I$(TOSDIR)/types \
          -I.

LIBMOTE = $(TOSDIR)/../support/sdk/c/libmote.a
#BUILD_EXTRA_DEPS += tn-injector #tn-listener
LISTEN_OBJS = collection_msg.o test_network_msg.o tn-listener.o $(LIBMOTE)
INJECT_OBJS = set_rate_msg.o tn-injector.o collection_debug_msg.o $(LIBMOTE)

# arguments: output filename stem, input filename, struct name
define mig_templ
MIGFILES += $(1).c $(1).h $(1).java $(1).o
$(1).c:
	mig -o $(1).h c -target=$$(PLATFORM) $$(CFLAGS) $$(TFLAGS) $(2) $(3)
$(1).java:
	mig -o $(1).java java -target=$$(PLATFORM) $$(CFLAGS) $$(TFLAGS) $(2) $(3)
endef

$(eval $(call mig_templ,test_network_msg,TestNetwork.h,TestNetworkMsg))
$(eval $(call mig_templ,set_rate_msg,$(TOSDIR)/lib/net/DisseminationEngine.h,dissemination_message))
$(eval $(call mig_templ,collection_debug_msg,$(TOSDIR)/lib/net/collection/CollectionDebugMsg.h,CollectionDebugMsg))

%.o: %.c
	gcc -v  $(TFLAGS) $(CFLAGS) -c -o $@ $<

tn-listener: $(LISTEN_OBJS)
	gcc -v $(TFLAGS) $(CFLAGS) -o $@ $(LISTEN_OBJS)

tn-injector: $(INJECT_OBJS)
	gcc -v $(TFLAGS) $(CFLAGS) -o $@ $(INJECT_OBJS)

#tn-listener.o: tn-listener.c
#	gcc $(TFLAGS) $(CFLAGS) -c -o $@ $<

tn-injector.o: tn-injector.c test_network_msg.c
	gcc $(TFLAGS) $(CFLAGS) -c -o $@ $<

#test_network_msg.c:
#	mig -o test_network_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) TestNetwork.h TestNetworkMsg 

#set_rate_msg.c:
#	mig -o set_rate_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TOSDIR)/lib/net/DisseminationEngine.h dissemination_message

#set_rate_msg.o: set_rate_msg.c
#	gcc $(CFLAGS) $(TFLAGS) -c -o $@ $<

#test_network_msg.o: test_network_msg.c
#	gcc $(CFLAGS) $(TFLAGS) -c -o $@ $<

#collection_msg.c:
#	mig -o collection_msg.h c -target=$(PLATFORM) $(CFLAGS) $(TFLAGS) $(TOSDIR)/lib/net/collection/ForwardingEngine.h collection_header

include $(MAKERULES)

migclean:
	rm -rf $(MIGFILES)
