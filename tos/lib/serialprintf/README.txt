Add a bare-serial printf component.

The SerialPrintfC component, when incorporated into an application, links
the platform-specific UartByte implementation into a global putchar function
where it will be used by the C runtime system as the destination for
printf(3c).  It allows easy access to a read-only stream of information from
the application without the overhead of using SerialActiveMessage.  You
should include <stdio.h> in your application code, but no other wiring or
include files are required.

In lineage, it is a horribly emasculated derivative of
tos/lib/printf/PrintfP, removing the buffering capability along with active
message support.

Use hyperterminal, minicom, or on Linux just cat /dev/ttyUSB0 to see the
output.  For the latter to work, you may need to run the following stty
command:

   stty 115200 min 1 time 5 -icrnl -parenb cs8 < /dev/ttyUSB0

Replace the first argument with the appropriate baud rate for your
application.

For compatibility with serial-focused terminal programs, the end-of-line
sequence in your code should be "\r\n".  Using just "\n" in these
environments causes the next line to be indented to the end of the previous
line.  When cat'ing /dev/serial, this often results in double-spaced output.
Depending on your default tty configuration, the -icrnl option in the stty
command above will prevent this behavior.
