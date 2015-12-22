configuration TestAppC{}
implementation {
	components MainC, TestC as App;
	App.Boot -> MainC;
}

