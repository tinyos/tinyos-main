TestPrintf

Description:

Tests the serial printf functionality. Printf's a message every 500ms, which displays an ever-increasing sequence number.
With the
PFLAGS += -DLONG_PRINT
option a string is printed five times after the basic message. Use it to test how the printf function handles large messages.
The string can be changed with
#PFLAGS += -DLONG_PRINT_MSG=\"custommessage\"
Default is "verylongmessagecomingthroughhopefullybufferspaceisadequate"

The am-printf-listener.py can be used to display AM-based printing. It uses the tos_noprintfhook python module, which does not filter out AM-type 100, used for printf messages.

Expected Result:

Basic
=====
[Iteration #0]
[Iteration #1]
[Iteration #2]
...

With default LONG_PRINT:
========================
[Iteration #0]
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
[Iteration #1]
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
verylongmessagecomingthroughhopefullybufferspaceisadequate
[Iteration #2]
...
