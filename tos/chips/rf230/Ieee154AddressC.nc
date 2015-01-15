configuration Ieee154AddressC{
	provides interface Ieee154Address;
}
implementation{
	components RF230RadioC;
	Ieee154Address = RF230RadioC;
}
