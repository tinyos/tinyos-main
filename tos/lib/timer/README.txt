This directory contains support for components that allow up to 256
individually managed alarms to be multiplexed onto a single hardware alarm.

The bulk of the implementation uses the TinyOS VirtualizeAlarmC component,
which is a generic that takes the alarm precision and size as parameters.
User code must instantiate new instances of a component where the precision
and size are coded into the compnent name.  To ease maintenance, only the
MuxAlarmMilli32* files are maintained: all other precision/size combinations
are derived from those by running the script generate.sh.

The list of files that are derived are maintained in the file generated.lst,
which itself is generated as a side effect of running generate.sh.  When
attempting to understand the system and do basic maintainance, it may be
worth running:

   cat generated.lst | xargs rm

to clear the clutter out of the way.
