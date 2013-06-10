COMPONENT=TestPacketLinkC
CFLAGS += -DPACKET_LINK
TOSMAKE_PRE_EXE_DEPS = PacketLinkMsg.java TestPacketLink.class
TOSMAKE_CLEAN_EXTRA = *.class PacketLinkMsg.java

PacketLinkMsg.java: TestPacketLink.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=PacketLinkMsg TestPacketLink.h PacketLinkMsg -o $@

TestPacketLink.class: $(wildcard *.java) TestPacketLink.java
	javac *.java

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
