
all:
	cd lib6lowpan && make
	cp lib6lowpan/lib6lowpan.a .

	cd driver && make
	cp driver/ip-driver .

clean:
	cd lib6lowpan && make clean
	cd driver && make clean
	rm lib6lowpan.a ip-driver
