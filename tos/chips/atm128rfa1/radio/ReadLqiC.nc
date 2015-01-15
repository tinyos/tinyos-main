configuration ReadLqiC {
	provides interface ReadLqi;
} implementation {
	components RFA1RadioC;
	ReadLqi = RFA1RadioC;
}
