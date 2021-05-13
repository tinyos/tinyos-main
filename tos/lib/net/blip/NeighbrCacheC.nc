

configuration NeighbrCacheC
{
	
	provides interface NeighbrCache;
	provides interface RouterList;

}


implementation
{

	components NeighbrCacheP as NP;
	NeighbrCache=NP;
	RouterList=NP;


	components NoLedsC as LedsC;
	NP.Leds->LedsC;


	components new TimerMilliC() as Timer;
	NP.Timer->Timer;

	components new TimerMilliC() as NUDTimer;
	NP.NUDTimer->NUDTimer;

	components NodeC;
	NP.Node->NodeC;



}
	
