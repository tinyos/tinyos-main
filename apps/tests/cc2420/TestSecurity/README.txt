README for TestSecurity

Author/Contact:
JeongGil Ko <jgko@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
Jong Hyun Lim <ljh@cs.jhu.edu>

Description:

SecAMSend provides an interface to send Active Message based packets
while using the CC2420 in-line security options.

Instructions:

All three in-line security options are implemented. The user can
enable each mode by selecting one of the three commands, setCtr() to
enable counter mode encryption, setCbcMac() to enable CBC-MAC
authentication, and setCcm() to enable both functions (CCM) to the
packet.

The first parameter of all options lets the user select which of the
two keys it will be using for security.

The second parameter, sets the number of payload bytes to skip for
encryption, number of bytes that will be skipped for authentication or
the number of bytes that will be authenticated but not encrypted. By
default when CCM is used the authentication starts at the byte after
the length byte. Setting this second parameter to 0 will encrypt
and/or sign all the payload, whereas, when this value is set to the
length of the payload no bytes will be encrypted and/or signed.

The third parameter for CBC-MAC and CCM are used to specify the number
of bytes in the authentication field. The user can select an even
number between 4 and 16 for this parameter.

After specifying the three options the user can call a normal AMSend
procedure to transmit secured packets.

Before this process please note that the setKey() command should be
used to specify the key the user desires to use for both the
transmitter and the receiver.

Please note that in the Makefile the flag CC2420_HW_SECURITY MUST be
added for the security features to be active.

Two application programs are included with security options
enabled. The first application, RadioCountToLeds1, is a modification
of RadioCountToLeds in the TinyOS 2.x repository. It dedicates one
node (TOS_NODE_ID 1) to be the transmitting node and other nodes to
receive its broadcast packets. Node 1 can use any of the three options
enabled. The second application, RadioCountToLeds2, is a modification
of the previous RadioCountToLeds1. Instead of only sending packets
with security enabled, node 1 sends each secured and un-secured
packets one at a time. The receivers distinguish between secured and
un-secured packets and process the un-secured ones through the normal
receive path and the secured ones through the secured receive path.

Known bugs/limitations:

None.
