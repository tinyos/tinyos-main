/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
 
 //TIMER ASYNC TELOSB
 

configuration TimerAsyncC
{
	//provides interface StdControl;
	provides interface TimerAsync;
}
implementation
{

	components LedsC;
	components TimerAsyncM;

	components new Alarm32khz32C() as Alarm;
	
	//StdControl = TimerAsyncM;
	TimerAsync = TimerAsyncM;
	
	TimerAsyncM.Leds -> LedsC;
	
	TimerAsyncM.AsyncTimer -> Alarm;

}
