configuration Ieee154AddressC{
	provides interface Ieee154Address;
}
implementation{
	components RFA1RadioC;
	Ieee154Address = RFA1RadioC;
}
