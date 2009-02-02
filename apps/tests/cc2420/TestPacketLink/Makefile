COMPONENT=TestPacketLinkC
CFLAGS += -DPACKET_LINK
BUILD_EXTRA_DEPS = PacketLinkMsg.java TestPacketLink.class
CLEAN_EXTRA = *.class PacketLinkMsg.java

PacketLinkMsg.java: TestPacketLink.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=PacketLinkMsg TestPacketLink.h PacketLinkMsg -o $@

TestPacketLink.class: $(wildcard *.java) TestPacketLink.java
	javac *.java

include $(MAKERULES)
