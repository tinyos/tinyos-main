
ifneq ($(filter lpl,$(MAKECMDGOALS)),)
	EXTRATARGETS+=lpl
endif

lpl: all

all:
	cd lib6lowpan && make
	cp lib6lowpan/lib6lowpan.a .
	cd driver && make $(EXTRATARGETS)

clean:
	cd lib6lowpan && make clean
	cd driver && make clean
	rm -f lib6lowpan.a ip-driver
