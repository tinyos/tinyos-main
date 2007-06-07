bin_SCRIPTS = motelist

dist_man_MANS = motelist.1

if CYGWIN
motelist: motelist-win32.cpp
	g++ -O3 -Wall -o motelist motelist-win32.cpp
else !CYGWIN
if DARWIN
motelist: motelist-macos
	cp motelist-macos motelist
else !DARWIN
motelist: motelist-linux
	cp motelist-linux motelist
endif
endif
