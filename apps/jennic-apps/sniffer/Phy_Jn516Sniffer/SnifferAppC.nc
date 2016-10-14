configuration SnifferAppC{}
implementation {
	components MainC, LedsC, SnifferC as App;
	App.Boot -> MainC;
	App.Leds -> LedsC;
}

